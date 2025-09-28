import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../features/auth/data/models/chore_model.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/auth/data/repositories/chores_repository.dart';
import '../../features/auth/data/repositories/user_repository.dart';

class ChoreCard extends StatefulWidget {
  final Chore chore;
  const ChoreCard({
    super.key,
    required this.chore,
  });

  @override
  State<ChoreCard> createState() => _ChoreCardState();
}

class _ChoreCardState extends State<ChoreCard> {
  final userRepo = UserRepository();
  final choresRepository = ChoresRepository();
  User? performer;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPerformer();
  }

  Future<void> _loadPerformer() async {
    try {
      final user = await userRepo.fetchUser(widget.chore.performer!);
      setState(() {
        performer = user;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  String getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return "-";
    final parts = name.trim().split(' ');
    return parts.take(2).map((e) => e[0]).join().toUpperCase();
  }

  String getDueText(DateTime now) {
    final dueDate = widget.chore.dueDate;
    if (dueDate == null) return "No due date";
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = due.difference(today).inDays;

    if (diff < 0) return "${-diff} day${-diff > 1 ? 's' : ''} overdue";
    if (diff == 0) return "Today";
    return "$diff day${diff > 1 ? 's' : ''} due";
  }

  IconData getStatusIcon(DateTime now) {
    final dueDate = widget.chore.dueDate;
    if (dueDate == null) return Icons.info_outline;
    final daysDiff = dueDate.difference(now).inDays;
    if (daysDiff < 0) return Icons.warning_amber_rounded;
    if (daysDiff == 0) return Icons.today_rounded;
    return Icons.schedule_rounded;
  }

  Color getStatusColor(DateTime now, ColorScheme colorScheme) {
    final dueDate = widget.chore.dueDate;
    if (dueDate == null) return colorScheme.outline;
    final daysDiff = dueDate.difference(now).inDays;
    if (daysDiff < 0) return colorScheme.error;
    if (daysDiff == 0) return Colors.purple;
    return colorScheme.tertiary;
  }

  String getStatusLabel(DateTime now) {
    final dueDate = widget.chore.dueDate;
    if (dueDate == null) return "-";

    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = due.difference(today).inDays;

    if (diff < 0) return "Overdue";
    if (diff == 0) return "Today";
    return "Upcoming";
  }

  String getDueDayText() {
    final dueDate = widget.chore.dueDate;
    if (dueDate == null) return "-";
    return DateFormat('EEEE').format(dueDate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: EdgeInsets.zero,
      elevation: 4, // Optional: Controlled by your cardTheme
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        splashFactory: InkRipple.splashFactory,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Title & Status Label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.chore.title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: getStatusColor(now, colorScheme).withAlpha(31),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      getStatusLabel(now),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: getStatusColor(now, colorScheme),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              /// Due Date & Performer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        getStatusIcon(now),
                        size: 18,
                        color: getStatusColor(now, colorScheme),
                      ),
                      const SizedBox(width: 6),
                      Text(getDueText(now), style: theme.textTheme.bodyMedium),
                    ],
                  ),
                  isLoading
                      ? const SizedBox(
                      height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        child: performer?.avatarSvg != null &&
                            performer!.avatarSvg!.isNotEmpty
                            ? SvgPicture.string(
                          performer!.avatarSvg!,
                          width: 32,
                          height: 32,
                        )
                            : Text(
                          getInitials(performer?.name),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        performer?.name != null
                            ? (performer!.name.length > 12 ? '${performer!.name.substring(0, 12)}…' : performer!.name)
                            : "-",
                        style: theme.textTheme.bodyMedium,
                      )
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              /// Task Type & Due Day
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.task_alt_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text(widget.chore.taskType.name, style: theme.textTheme.labelLarge),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text(getDueDayText(), style: theme.textTheme.labelLarge),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
