import 'package:domyturn/core/storage/secure_storage_service.dart';
import 'package:domyturn/features/auth/data/repositories/home_repository.dart';
import 'package:domyturn/features/auth/data/repositories/notification_repository.dart';
import 'package:domyturn/shared/utils/global_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/session/app_session.dart';
import '../../../../shared/widgets/chore_card.dart';
import '../../data/models/chore_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/chores_repository.dart';
import '../../data/repositories/user_repository.dart';
import 'edit_chore_screen.dart';

class ChoresScreen extends StatefulWidget {
  const ChoresScreen({super.key});

  @override
  State<ChoresScreen> createState() => _ChoresScreenState();
}

class _ChoresScreenState extends State<ChoresScreen> {
  final ChoresRepository _repository = ChoresRepository();
  final UserRepository _userRepository = UserRepository();
  final HomeRepository _homeRepository = HomeRepository();
  final NotificationRepository _notificationRepository = NotificationRepository();

  bool isUserAbsent = false;
  bool isAwaitingApproval = false;
  bool isLoadingAbsence = false;
  bool isLoadingApprovals = false;
  bool isApproved = false;
  late Future<List<Chore>> _choresFuture;

  @override
  void initState() {
    super.initState();
    _loadChores();
    _loadAbsenceStatus();
  }

  void _loadChores() {
    setState(() {
      _choresFuture = _repository.fetchTasks();
    });
  }

  Future<void> _loadAbsenceStatus() async {
    setState(() => isLoadingAbsence = true);
    try {
      final status = await _homeRepository.fetchAbsenceStatus();
      setState(() {
        switch (status) {
          case 'APPROVED':
            isUserAbsent = true;
            isAwaitingApproval = false;
            break;
          case 'PENDING':
            isUserAbsent = true;
            isAwaitingApproval = true;
            break;
          case 'PRESENT':
          default:
            isUserAbsent = false;
            isAwaitingApproval = false;
        }
      });
    } catch (e) {
      GlobalScaffold.showSnackbar("Failed to load absence status: $e",type: SnackbarType.error);
    } finally {
      setState(() => isLoadingAbsence = false);
    }
  }

  void _navigateToCreateChore(BuildContext context) async {
    await context.push('/create-chore');
    _loadChores(); // Refresh after returning
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
    required Future<void> Function() onConfirm,
  }) async {
    bool confirmed = false;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await onConfirm();
              confirmed = true;
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    return confirmed;
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: color,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: alignment,
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  void _showChoreBottomSheet(BuildContext context, Chore chore) async {
    final user = chore.performer != null
        ? await _userRepository.fetchUser(chore.performer!)
        : null;
    final List<User> assignees = await _userRepository.fetchUsersInOrder(chore.assignees,chore.completedUsers);

    bool showDescription = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final now = DateTime.now();
            final isOverdue = chore.dueDate != null && chore.dueDate!.isBefore(now);
            final currentUser = AppSession.instance.userId;
            final isPerformer = currentUser == chore.performer;
            final filteredAssignees = assignees.where((u) => u.id != chore.performer).toList();
            print("Now: $now");
            print("Due: ${chore.dueDate}");
            print("currentUser: $currentUser");
            print("Performer: ${chore.performer}");
            print("isOverdue: $isOverdue");
            print("isPerformer: $isPerformer");
            print("Home id : ${chore.homeId}");
            print("chore id : ${chore.id}");

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Line 1: Cancel & Edit
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.arrow_downward),
                          label: const Text("Cancel"),
                          onPressed: () => Navigator.pop(context),
                        ),

                        if (isOverdue && !isPerformer)
                          IconButton(
                            tooltip: 'Send Reminder',
                            icon: const Icon(Icons.notifications_active_outlined),
                            onPressed: () async {
                              await _notificationRepository.sendReminderToUser(
                                userId: chore.performer!,
                                title :chore.title);
                              GlobalScaffold.showSnackbar("Reminder sent to performer",type: SnackbarType.info);
                            },
                          ),

                        TextButton.icon(
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text("Edit"),
                          onPressed: () async {
                            Navigator.pop(context);
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditChoreScreen(choreId: chore.id!),
                              ),
                            );
                            if (updated == true) _loadChores();
                          },
                        ),
                      ],
                    ),

                    // Line 2: Due date + Performer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (chore.dueDate != null)
                          Text(
                            _getDueDateLabel(chore.dueDate!.toLocal()),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              shadows: [const Shadow(color: Colors.black12, blurRadius: 2)],
                              color: chore.dueDate!.toLocal().isBefore(
                                DateTime.now().subtract(const Duration(days: 1)),
                              )
                                  ? Colors.red
                                  : null,
                            ),
                          ),
                        if (user != null)
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: user.avatarSvg != null
                                    ? FittedBox(
                                  child: SvgPicture.string(user.avatarSvg!, width: 28, height: 28),
                                )
                                    : Text(
                                  user.name[0],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                user.name.length > 12 ? '${user.name.substring(0, 12)}…' : user.name,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Line 3: Title
                    Text(
                      chore.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Line 4: Chore type + date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.task_alt_rounded),
                            const SizedBox(width: 8),
                            Text(
                              chore.taskType.name,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (chore.dueDate != null)
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_outlined),
                              const SizedBox(width: 6),
                              Text(
                                chore.dueDate!.toLocal().toString().split(' ')[0],
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Line 5: Assignees
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: assignees.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final u = assignees[index];

                            // Skip performer
                            if (u.id == chore.performer) return const SizedBox.shrink();

                            return Chip(
                              label: Text(
                                u.name.length > 10 ? '${u.name.substring(0, 10)}…' : u.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            );
                          }
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Line 6: View Description + Mark Done
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() => showDescription = !showDescription);
                          },
                          icon: Icon(showDescription ? Icons.expand_less : Icons.expand_more),
                          label: const Text("View Description"),
                        ),
                        FilledButton(
                          onPressed: () async {
                            final userId = await AppSession.instance.userId; // Get the current user ID
                            if (!chore.assignees.contains(userId)) {
                              GlobalScaffold.showSnackbar("You are not part of this task",type: SnackbarType.error);
                              Navigator.pop(context); // Optionally close the dialog or bottom sheet
                              return;
                            }
                            Navigator.pop(context);
                            await _repository.markTaskDone(chore.id!);
                           GlobalScaffold.showSnackbar("Chore marked as done",type: SnackbarType.success);
                            _loadChores();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Mark as Done"),
                        ),
                      ],
                    ),

                    if (showDescription) ...[
                      const SizedBox(height: 12),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: SingleChildScrollView(
                          child: Text(
                            chore.description.isNotEmpty
                                ? chore.description
                                : "No description available.",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontStyle: chore.description.isNotEmpty
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                              color: chore.description.isNotEmpty
                                  ? null
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getDueDateLabel(DateTime? dueDate) {
    if (dueDate == null) return "No due date";

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.toLocal().year, dueDate.toLocal().month, dueDate.toLocal().day);
    final diff = due.difference(today).inDays;

    if (diff == 0) return "Due Today";
    if (diff > 0) return "Due in $diff day${diff > 1 ? 's' : ''}";
    return "Overdue by ${-diff} day${-diff > 1 ? 's' : ''}";
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final SecureStorageService storageService = SecureStorageService();
    return FutureBuilder<List<Chore>>(
      future: _choresFuture,
      builder: (context, snapshot) {
        final chores = snapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(
            title: const Text("Chores"),
            scrolledUnderElevation: 1.5,
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: buildAbsenceToggle(),
              ),
            ],
          ),

          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateToCreateChore(context),
            icon: const Icon(Icons.add),
            label: const Text("Add Chore"),
            extendedPadding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          body: () {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text("Failed to load chores"));
            } else if (chores.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.task_alt, size: 64, color: colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      "Start organizing!",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Add your first chore to stay productive",
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: chores.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final chore = chores[index];

                return Dismissible(
                  key: ValueKey(chore.id),
                  direction: DismissDirection.horizontal,
                  background: _buildSwipeBackground(
                    color: Colors.green,
                    icon: Icons.check_circle_outline,
                    alignment: Alignment.centerLeft,
                  ),
                  secondaryBackground: _buildSwipeBackground(
                    color: Colors.red,
                    icon: Icons.delete_outline,
                    alignment: Alignment.centerRight,
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {

                      final userId = await AppSession.instance.userId; // 🔐 Get current user ID

                      if (!chore.assignees.contains(userId)) {
                        GlobalScaffold.showSnackbar("You are not part of this task",type: SnackbarType.error);
                        return false; // ❌ Cancel the swipe action
                      }
                      return await _showConfirmationDialog(
                        title: "Mark as Done?",
                        content: "Are you sure you want to mark this chore as done?",
                        onConfirm: () async {
                          await _repository.markTaskDone(chore.id!);
                          GlobalScaffold.showSnackbar("Chore marked as done",type: SnackbarType.success);
                          _loadChores();
                        },
                      );
                    } else if (direction == DismissDirection.endToStart) {
                      final userId = await AppSession.instance.userId;
                      if (!chore.assignees.contains(userId)) {
                        GlobalScaffold.showSnackbar("You are not part of this task",type: SnackbarType.error);
                        return false; // prevent dismissal
                      }
                      return await _showConfirmationDialog(
                        title: "Delete Chore?",
                        content: "Are you sure you want to delete this chore?",
                        onConfirm: () async {
                          await _repository.deleteTask(chore.id!);
                          GlobalScaffold.showSnackbar("Chore deleted",type: SnackbarType.success);
                          _loadChores();
                        },
                      );
                    }
                    return false;
                  },
                  child: GestureDetector(
                    onTap: () => _showChoreBottomSheet(context, chore),
                    child: ChoreCard(chore: chore),
                  ),
                );
              },
            );
          }(),
        );
      },
    );
  }

  Widget buildAbsenceToggle() {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(
            "Absent",
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (isLoadingAbsence)
          const SizedBox(
            width: 52,
            height: 32,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          Switch(
            value: isUserAbsent,
            onChanged: (value) async {
              final confirmed = await _showConfirmationDialog(
                title: value ? "Mark Yourself as Absent?" : "Cancel Absence?",
                content: value
                    ? "You’ll be excluded from chores. Others must approve or it auto-approves in 1 hour."
                    : "You’ll be reassigned to chores immediately.",
                onConfirm: () async {
                  setState(() => isLoadingAbsence = true);
                  try {
                    if (value && !isUserAbsent) {
                      await _homeRepository.markUserAbsent();
                      GlobalScaffold.showSnackbar("Marked as absent",type: SnackbarType.success);
                    } else if (!value && isUserAbsent) {
                      await _homeRepository.cancelUserAbsent();
                      GlobalScaffold.showSnackbar("Absence cancelled",type: SnackbarType.info);
                    }

                    await _loadAbsenceStatus();
                  } catch (e) {
                    GlobalScaffold.showSnackbar("Failed to update absence: $e",type: SnackbarType.error);
                  } finally {
                    setState(() => isLoadingAbsence = false);
                  }
                },
              );
            },

            // ✅ Only the THUMB changes based on status
            thumbIcon: WidgetStateProperty.all<Icon?>(
              isAwaitingApproval
                  ? const Icon(Icons.hourglass_top, size: 18)
                  : isUserAbsent
                  ? const Icon(Icons.task_alt, size: 18)
                  : const Icon(Icons.person_off_outlined, size: 18),
            ),
            thumbColor: WidgetStateProperty.all<Color>(
              isAwaitingApproval
                  ? Colors.amber.shade700
                  : isUserAbsent
                  ? colorScheme.primary
                  : colorScheme.outline,
            ),

            // ✅ Always muted track color
            trackColor: WidgetStateProperty.all<Color>(
              colorScheme.surfaceVariant,
            ),
          ),
      ],
    );
  }


}
