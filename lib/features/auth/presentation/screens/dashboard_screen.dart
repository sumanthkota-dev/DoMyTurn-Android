import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:domyturn/features/auth/data/repositories/chores_repository.dart';
import 'package:domyturn/features/auth/data/repositories/home_repository.dart';
import 'package:domyturn/features/auth/data/repositories/dashboard_repository.dart';
import '../../data/models/activity_model.dart';
import '../../data/models/chore_model.dart';
import '../../data/models/shopping_item_model.dart';
import '../../data/models/user_model.dart';


final dashboardRepositoryProvider = Provider((ref) => DashboardRepository());
final homeRepositoryProvider = Provider((ref) => HomeRepository());
final choresRepositoryProvider = Provider((ref) => ChoresRepository());

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    final dashboardRepo = ref.read(dashboardRepositoryProvider);
    final homeRepo = ref.read(homeRepositoryProvider);
    final choresRepo = ref.read(choresRepositoryProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
            children: [
              // 🏠 Home Card
              _buildFixedHeightCard(
                context: context,
                height: screenHeight * 0.21,
                onTap: () => context.push('/home'),
                title: "Home",
                future: Future.wait([
                  dashboardRepo.fetchHomeMembers(),
                  homeRepo.fetchAbsentUserIds(),
                  choresRepo.fetchTasks(),
                  dashboardRepo.fetchShoppingItems(),
                ]),
                fallback: [
                  <User>[],
                  <int>{},
                  <Chore>[],
                  <ShoppingItem>[],
                ],
                builder: (data) => _buildHomeCardContent(
                  context,
                  members: data[0] as List<User>,
                  absentIds: data[1] as Set<int>,
                  chores: data[2] as List<Chore>,
                  shopping: data[3] as List<ShoppingItem>,
                ),
              ),

              const SizedBox(height: 12),

              // 🧹 Chores Card
              _buildFixedHeightCard(
                context: context,
                height: screenHeight * 0.21,
                title: "Your Chores",
                future: dashboardRepo.fetchUserChores(),
                fallback: const <Chore>[],
                builder: (chores) => _buildChoresList(context, chores),
              ),


              const SizedBox(height: 12),

              // 📊 Activities & 🛒 Shopping Cards
              SizedBox(
                height: screenHeight * 0.37,
                child: Row(
                  children: [
                    // Activities
                    Expanded(
                      child: _buildFixedHeightCard(
                        context: context,
                        height: screenHeight * 0.37,
                        padding: const EdgeInsets.only(right: 6),
                        title: "Recent Activities",
                        future: dashboardRepo.fetchRecentActivities(),
                        fallback: const <Activity>[],
                        builder: (activities) => _buildActivityList(context, activities),
                      ),
                    ),
                    // Shopping List
                    Expanded(
                      child: _buildFixedHeightCard(
                        context: context,
                        height: screenHeight * 0.37,
                        padding: const EdgeInsets.only(left: 6),
                        title: "Shopping List",
                        future: dashboardRepo.fetchShoppingItems(),
                        fallback: const <ShoppingItem>[],
                        builder: (items) => _buildShoppingList(context, items),
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
    );
  }

  Widget _buildFixedHeightCard<T>({
    required BuildContext context,
    required String title,
    required double height,
    required Future<List<T>> future,
    required Widget Function(List<T>) builder,
    required List<T> fallback, // 👈 Add fallback data here
    EdgeInsets? padding,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return SizedBox(
      height: height,
      width: double.infinity, // Ensures full width in Column
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: double.infinity,
            child: Card(
              clipBehavior: Clip.antiAlias,
              elevation: theme.cardTheme.elevation ?? 4,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: FutureBuilder<List<T>>(
                        future: future,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return builder(fallback);
                          } else if (snapshot.hasError) {
                            return builder(fallback);
                          } else if (!snapshot.hasData) {
                            return const Center(child: Text("No data"));
                          } else {
                            return builder(snapshot.data!);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildHomeCardContent(
      BuildContext context, {
        required List<User> members,
        required Set<int> absentIds,
        required List<Chore> chores,
        required List<ShoppingItem> shopping,
      }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),

            // 🧠 Always on top - Quote
            Text(
              "“Great responsibility comes with great power.”",
              style: theme.textTheme.labelLarge?.copyWith(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // 📊 Stats (Icons + Labels)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 32,
              runSpacing: 16,
              children: [
                _statItem(Icons.groups_2_outlined, "Members", members.length.toString(), theme),
                _statItem(Icons.block, "Absent", absentIds.length.toString(), theme),
                _statItem(Icons.check_circle_outline, "Chores", chores.length.toString(), theme),
                _statItem(Icons.shopping_cart_outlined, "Lists", shopping.length.toString(), theme),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildChoresList(BuildContext context, List<Chore> chores) {
    if (chores.isEmpty) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.coffee, size: 48, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              "No chores, enjoy your coffee!",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: chores.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final chore = chores[index];
        final due = chore.dueDate;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        String label = "No due date";
        String date = "-";
        Color color = colorScheme.outline;

        if (due != null) {
          final now = DateTime.now();
          final days = due.difference(now).inDays;
          date = "${due.day.toString().padLeft(2, '0')} ${_monthAbbreviation(due.month)}";

          if (days < 0) {
            label = "Overdue";
            color = colorScheme.error;
          } else if (days == 0) {
            label = "Due today";
            color = colorScheme.scrim;
          } else {
            label = "Due in $days days";
            color = colorScheme.primary;
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(chore.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  )),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label,
                      style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w500)),
                  Text(date,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                      )),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityList(BuildContext context, List<Activity> activities) {
    return SingleChildScrollView(
      child: Column(
        children: activities.map((activity) {
          return Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt, size: 18, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Expanded(child: Text(activity.action)),
                ],
              ),
              const Divider(height: 16, thickness: 0.5),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildShoppingList(BuildContext context, List<ShoppingItem> items) {
    if (items.isEmpty) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

      return Center(
        child: GestureDetector(
          onTap: () => context.go('/shopping'),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle, size: 36, color: colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                "Add items",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }


    return GestureDetector(
      onTap: () => context.go('/shopping'),
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(item.listName,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...item.items.take(2).map(
                      (product) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 18),
                        const SizedBox(width: 6),
                        Expanded(child: Text(product)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _monthAbbreviation(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  Widget _statItem(IconData icon, String label, String value, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 28, color: theme.colorScheme.primary),
        const SizedBox(height: 6),
        Text(
          "$label: $value",
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

}
