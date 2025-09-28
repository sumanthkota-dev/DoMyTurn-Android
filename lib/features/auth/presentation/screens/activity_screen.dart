import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/activity_model.dart';
import '../../data/repositories/activity_repository.dart';

class ActivityScreen extends StatelessWidget {
  ActivityScreen({super.key});

  final ActivityRepository _repository = ActivityRepository();

  // Group activities by formatted date (e.g., "Monday, June 10")
  Map<String, List<Activity>> groupActivitiesByDate(List<Activity> activities) {
    final Map<String, List<Activity>> grouped = {};

    for (var activity in activities) {
      final dateStr = DateFormat('EEEE, MMMM d').format(activity.timestamp);
      grouped.putIfAbsent(dateStr, () => []).add(activity);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Activity"),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Activity>>(
        future: _repository.fetchActivities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading activities"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No activities found"));
          }

          final groupedActivities = groupActivitiesByDate(snapshot.data!);

          return ListView.builder(
            itemCount: groupedActivities.length,
            itemBuilder: (context, index) {
              final dateKey = groupedActivities.keys.elementAt(index);
              final dayActivities = groupedActivities[dateKey]!;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateKey,
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...dayActivities.map(
                          (activity) => Card(
                        shape: theme.cardTheme.shape,
                        elevation: theme.cardTheme.elevation,
                        color: theme.cardTheme.color,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.notifications, color: colorScheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activity.action,
                                      style: textTheme.bodyLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('hh:mm a').format(activity.timestamp),
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
