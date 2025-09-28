import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:domyturn/features/auth/data/models/absent_user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:logger/logger.dart';
import '../../../../core/session/app_session.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/models/home_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/home_repository.dart';
import '../../data/repositories/user_repository.dart';
import 'edit_home_screen.dart';
import 'package:go_router/go_router.dart';

final _homeRepo = HomeRepository();
final _userRepo = UserRepository();
final logger = Logger(printer: PrettyPrinter());
final AutoDisposeFutureProvider<Home> homeProvider = FutureProvider.autoDispose<Home>((ref) async {
  return await _homeRepo.fetchHomeDetails();
});

final AutoDisposeFutureProvider<List<User>> homeMembersProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  await ref.watch(homeProvider.future);
  return await _userRepo.fetchUsers();
});
final approvedAbsenteesProvider = FutureProvider.autoDispose<List<AbsentUser>>((ref) async {
  return await HomeRepository().fetchAbsentUsers();
});


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.refresh(homeProvider);
      ref.refresh(homeMembersProvider);
      loadPendingAbsentees();
      loadApprovedAbsentees();
    });
  }
  List<User> _pendingUsers = [];
  List<AbsentUser> _approvedAbsentees = [];

  Future<void> loadPendingAbsentees() async {
    try {
      final homeIdStr = await SecureStorageService().readValue('homeId');
      final userIdStr = await SecureStorageService().readValue('userId');

      if (homeIdStr == null || userIdStr == null) {
        throw Exception("homeId or userId not found in secure storage");
      }

      final homeId = int.parse(homeIdStr);
      final currentUserId = int.parse(userIdStr);

      final absentIds = await _homeRepo.fetchPendingUserIds(homeId);
      final filteredIds = absentIds.where((id) => id != currentUserId).toList();

      final users = await _userRepo.fetchAbsentUsersInHome(homeId, filteredIds);
      logger.i("Pending Users : "+users.toString());
      setState(() {
        _pendingUsers = users;
      });
    } catch (e) {
      logger.e("Failed to load pending absentees: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load pending absentees")),
      );
    }
  }

  Future<void> loadApprovedAbsentees() async {
    try {
      final approved = await _homeRepo.fetchAbsentUsers();

      setState(() {
        _approvedAbsentees = approved;
      });
    } catch (e) {
      logger.e("Failed to load approved absentees: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load currently absent users")),
      );
    }
  }


  void showQrCodeSheet(BuildContext context, int homeId) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final maxWidth = screenWidth > 600 ? 500.0 : screenWidth;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Scan to Join Home', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 24),
                  FutureBuilder<Response>(
                    future: _homeRepo.fetchQrCode(homeId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        );
                      } else if (snapshot.hasError) {
                        return Column(
                          children: [
                            const Icon(Icons.error_outline, size: 40, color: Colors.red),
                            const SizedBox(height: 8),
                            Text("Failed to load QR code", style: theme.textTheme.bodyMedium),
                          ],
                        );
                      } else if (snapshot.hasData) {
                        final bytes = snapshot.data!.data as List<int>;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withAlpha(26),
                                theme.colorScheme.secondary.withAlpha(13),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withAlpha(76),
                                blurRadius: 30,
                                spreadRadius: 4,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(
                              Uint8List.fromList(bytes),
                              width: 220,
                              height: 220,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  FutureBuilder<String?>(
                    future: _homeRepo.fetchInviteLink(homeId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError || snapshot.data == null) {
                        return const Text("Failed to load invite link");
                      } else {
                        final link = snapshot.data!;
                        return FilledButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: link));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Invite link copied!")),
                            );
                          },
                          icon: const Icon(Icons.link),
                          label: const Text("Copy Invite Link"),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Divider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 12),
                  Text(
                    'Anyone with this code or link can join your home.\nShare it responsibly.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(homeProvider);
    final membersAsync = ref.watch(homeMembersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Home"),
        automaticallyImplyLeading: true,
        actions: [
          homeAsync.when(
            data: (home) => IconButton(
              icon: const Icon(Icons.qr_code),
              onPressed: () => showQrCodeSheet(context, home.id),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: homeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text("Home Load Error: $e")),
          data: (home) {
            return membersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text("User Load Error: $e")),
              data: (users) {
                return SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHomeCard(theme, home, context),
                            const SizedBox(height: 24),
                            _buildMembersCard(theme, users),
                            const SizedBox(height: 24),
                            buildCurrentlyAbsentCard(), // ✅ currently absent card
                            const SizedBox(height: 24),
                            buildPendingAbsenteesList(), // ✅ pending approval list
                            const SizedBox(height: 32),
                            Center(
                              child: FilledButton.tonalIcon(
                                onPressed: () => _handleLeaveHome(context),
                                icon: const Icon(Icons.logout),
                                label: const Text("Leave Home"),
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.colorScheme.errorContainer.withAlpha(50),
                                  foregroundColor: theme.colorScheme.error,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHomeCard(ThemeData theme, Home home, BuildContext context) {
    final formattedAddress = '${home.address}, ${home.city}, ${home.state}, ${home.pincode}, ${home.country}';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      surfaceTintColor: theme.colorScheme.surfaceVariant,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // ⬅️ adaptive height
          children: [
            Row(
              children: [
                const Icon(Icons.home_rounded, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    home.name,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: "Edit Home",
                  onPressed: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EditHomeScreen(home: home)),
                    );
                    if (updated == true) ref.invalidate(homeProvider);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formattedAddress,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersCard(ThemeData theme, List<User> members) {
    final displayedMembers = members.take(10).toList();
    final rows = <List<User>>[];
    for (int i = 0; i < displayedMembers.length; i += 5) {
      rows.add(displayedMembers.skip(i).take(5).toList());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            "Members",
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),

        /// 📦 Card with responsive width
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600), // ✅ Tablet-safe width
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              margin: const EdgeInsets.symmetric(horizontal: 8), // Optional padding
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Column(
                  children: rows.map((rowMembers) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: rowMembers.map((user) {
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _showUserInfoDialog(context, user),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: theme.colorScheme.primaryContainer.withAlpha(50),
                                    child: user.avatarSvg != null && user.avatarSvg!.isNotEmpty
                                        ? SvgPicture.string(user.avatarSvg!)
                                        : Text(
                                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        color: theme.colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    user.name.split(" ").first,
                                    style: theme.textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showUserInfoDialog(BuildContext context, User user) {
    final theme = Theme.of(context);
    final copied = ValueNotifier<String?>(null);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Stack(
        children: [
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent)),
          Center(
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(230),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: ValueListenableBuilder<String?>(
                  valueListenable: copied,
                  builder: (context, copiedField, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                          tooltip: "Close",
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      Center(
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: theme.colorScheme.primary.withAlpha(30),
                          child: user.avatarSvg != null && user.avatarSvg!.isNotEmpty
                              ? SvgPicture.string(user.avatarSvg!, height: 120, width: 120)
                              : Text(
                            user.name.isNotEmpty ? user.name[0] : "?",
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(user.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 20),
                      _buildCopyRow(theme, Icons.email_outlined, user.email, 'email', copied),
                      const SizedBox(height: 8),
                      _buildCopyRow(theme, Icons.phone_outlined, user.mobile, 'mobile', copied),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyRow(ThemeData theme, IconData icon, String value, String field, ValueNotifier<String?> copied) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        IconButton(
          icon: Icon(
            copied.value == field ? Icons.check : Icons.copy,
            size: 18,
            color: copied.value == field ? theme.colorScheme.primary : theme.iconTheme.color,
          ),
          tooltip: "Copy",
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            copied.value = field;
            Future.delayed(const Duration(seconds: 2), () => copied.value = null);
          },
        ),
      ],
    );
  }

  Widget buildPendingAbsenteesList() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            "Absentees Approvals",
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          surfaceTintColor: colorScheme.surfaceVariant,
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: _pendingUsers.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, color: colorScheme.primary, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    "No pending absentees",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
                : Column(
              children: _pendingUsers
                  .map((user) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _buildApprovalChip(user),
              ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalChip(User user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.secondaryContainer,
            child: user.avatarSvg != null
                ? SvgPicture.string(user.avatarSvg!, width: 50, height: 50)
                : Text(
              user.name[0].toUpperCase(),
              style: TextStyle(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              user.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: () async {
              try {
                await _homeRepo.approveAbsence(user.id);
                await loadPendingAbsentees();
                await loadApprovedAbsentees();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Approved ${user.name}'s absence")),
                );
                await loadPendingAbsentees();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Approval failed: $e")),
                );
              }
            },
            icon: const Icon(Icons.check, size: 20),
            label: const Text("Approve"),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLeaveHome(BuildContext context) async {
    try {
      final home = await _homeRepo.fetchHomeDetails();
      final userIdStr = await SecureStorageService().readValue('userId');
      final userId = int.tryParse(userIdStr ?? '');

      if (userId == null) throw Exception("User ID not found");

      final members = await _userRepo.fetchUsers();
      final otherMembers = members.where((u) => u.id != userId).toList();

      // 🔴 Creator flow
      if (home.creatorId == userId) {
        if (otherMembers.isEmpty) {
          // ✅ Only member —> delete home
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Delete Home"),
              content: const Text("You're the only member. Do you want to delete this home?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Delete"),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await _homeRepo.deleteHome();
            await AppSession.instance.clearHomeId();
            if (context.mounted) {
              GoRouter.of(context).go('/create-or-join-home');
            }
          }
          return;
        }

        // ✅ Has other members — must assign new creator before leaving
        int? selectedId;
        bool creatorUpdated = false;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text("Assign New Creator"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("You are the current home creator. Please assign another member before leaving."),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: otherMembers.map((user) {
                          final isSelected = selectedId == user.id;
                          return ChoiceChip(
                            label: Text(
                              user.name.length > 10 ? user.name.substring(0, 10) : user.name,
                            ),
                            selected: isSelected,
                            onSelected: (_) => setState(() => selectedId = user.id),
                            selectedColor: Theme.of(context).colorScheme.primaryContainer,
                            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                            labelStyle: Theme.of(context).textTheme.bodyMedium,
                          );
                        }).toList(),
                      ),
                      if (creatorUpdated)
                        const Padding(
                          padding: EdgeInsets.only(top: 16.0),
                          child: Text(
                            "Creator updated successfully. You can now leave the home.",
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                    ],
                  ),
                  actions: [
                    if (!creatorUpdated)
                      ElevatedButton.icon(
                        onPressed: selectedId != null
                            ? () async {
                          await _homeRepo.assignNewCreator(selectedId!);
                          if (context.mounted) {
                            setState(() => creatorUpdated = true);
                          }
                        }
                            : null,
                        icon: const Icon(Icons.update),
                        label: const Text("Update Creator"),
                      ),
                    if (creatorUpdated)
                      TextButton(
                        onPressed: () async {
                          final confirmLeave = await showDialog<bool>(
                            context: dialogContext,
                            builder: (_) => AlertDialog(
                              title: const Text("Leave Home"),
                              content: const Text("Do you want to leave this home now?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext, false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext, true),
                                  child: const Text("Leave"),
                                ),
                              ],
                            ),
                          );

                          if (confirmLeave == true) {
                            print("👉 Confirmed leave, now calling leaveHome and clearing session");
                            await _homeRepo.leaveHome();
                            await AppSession.instance.clearHomeId();
                            print("✅ HomeId should now be null");
                            if (context.mounted) {
                              GoRouter.of(context).go('/create-or-join-home');
                            }
                          }
                        },
                        child: const Text("Leave Home"),
                      ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text("Cancel"),
                    ),
                  ],
                );
              },
            );
          },
        );
      }

      // 🔵 Non-creator flow
      else {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Leave Home"),
            content: const Text("Are you sure you want to leave this home?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Leave"),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await _homeRepo.leaveHome();
          await AppSession.instance.clearHomeId();
          if (context.mounted) {
            GoRouter.of(context).go('/create-or-join-home');
          }
        }
      }
    } catch (e) {
      _showError("Error: $e");
    }
  }

  Widget buildCurrentlyAbsentCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            "Currently Absent",
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          surfaceTintColor: colorScheme.surfaceVariant,
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 80), // ✅ minimum height
            padding: const EdgeInsets.all(16),
            child: _approvedAbsentees.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sentiment_satisfied_alt,
                      color: colorScheme.primary, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    "All members are present",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
                : SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _approvedAbsentees.map((user) {
                  final name = user.name.length > 10
                      ? '${user.name.substring(0, 10)}...'
                      : user.name;

                  return Chip(
                    avatar: const Icon(Icons.hiking, size: 20),
                    label: Text(name),
                    backgroundColor: colorScheme.secondaryContainer,
                    shape: const StadiumBorder(),
                    labelStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }
}
