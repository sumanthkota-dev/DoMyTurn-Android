import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/provider/change_notifier_provider.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionProvider); // ✅ Now reactive
    print("✅ MainScaffold rebuilt with homeId: ${session.homeId}");
    final homeId = session.homeId;
    final location = GoRouterState.of(context).uri.toString();

    final bool hasHome = homeId != null && homeId != 0;
    print("Home Nav: $hasHome"+" Home Id : $homeId");

    final routes = hasHome
        ? ['/dashboard', '/activities', '/chores', '/shopping', '/profile']
        : ['/create-or-join-home', '/profile'];

    final destinations = hasHome
        ? const [
      _NavItem(Icons.dashboard, 'Dashboard'),
      _NavItem(Icons.history, 'Activities'),
      _NavItem(Icons.list, 'Chores'),
      _NavItem(Icons.shopping_cart, 'Shopping'),
      _NavItem(Icons.person, 'Profile'),
    ]
        : const [
      _NavItem(Icons.home, 'Join Home'),
      _NavItem(Icons.person, 'Profile'),
    ];

    final currentIndex = routes
        .indexWhere((r) => location.startsWith(r))
        .clamp(0, routes.length - 1);

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: child,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        onDestinationSelected: (index) {
          final route = routes[index];
          if (!location.startsWith(route)) {
            context.go(route);
          }
        },
        destinations: destinations
            .map((item) => NavigationDestination(
          icon: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon),
              const SizedBox(height: 2),
              Text(item.label, style: const TextStyle(fontSize: 11)),
            ],
          ),
          label: '',
        ))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
