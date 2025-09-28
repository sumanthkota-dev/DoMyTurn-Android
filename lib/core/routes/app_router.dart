
import 'package:domyturn/features/auth/presentation/screens/qr_join_home_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/presentation/screens/registration_screen.dart';
import '../../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/activity_screen.dart';
import '../../features/auth/presentation/screens/chores_screen.dart';
import '../../features/auth/presentation/screens/create_chore_screen.dart';
import '../../features/auth/presentation/screens/create_join_home_screen.dart';
import '../../features/auth/presentation/screens/dashboard_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/home_screen.dart';
import '../../features/auth/presentation/screens/invite_link_screen.dart';
import '../../features/auth/presentation/screens/invite_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/qr_code_view_screen.dart';
import '../../features/auth/presentation/screens/shopping_screen.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../provider/change_notifier_provider.dart';
import '../session/app_session.dart';

class AppRouter {
  static GoRouter router(String initialRoute,GlobalKey<NavigatorState> navigatorKey,) {
    return GoRouter(
      initialLocation: initialRoute,
      navigatorKey: navigatorKey,
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegistrationScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/otp',
          builder: (context, state) {
            final email = state.uri.queryParameters['email'] ?? '';
            final otpAlreadySent = state.uri.queryParameters['sent'] == 'true';
            return OtpScreen(email: email, otpAlreadySent: otpAlreadySent);
          },
        ),
        ShellRoute(
          builder: (context, state, child) {
            return Consumer(
              builder: (context, ref, _) {
                final homeId = ref.watch(appSessionProvider).homeId;

                return MainScaffold(
                  key: ValueKey(homeId), // this forces rebuild
                  child: child,
                );
              },
            );
          },
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => DashboardScreen(),
            ),
            GoRoute(
              path: '/chores',
              builder: (context, state) => ChoresScreen(),
            ),
            GoRoute(
              path: '/shopping',
              builder: (context, state) => ShoppingScreen(),
            ),
            GoRoute(
              path: '/activities',
              builder: (context, state) => ActivityScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => ProfileScreen(),
            ),
            GoRoute(
              path: '/create-or-join-home',
              builder: (context, state) => const CreateJoinHomeScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/create-or-join-home',
          builder: (context, state) => const CreateJoinHomeScreen(),
        ),
        GoRoute(
          path: '/scan',
          builder: (context, state) => const QrJoinHomeScreen(),
        ),
        GoRoute(
          path: '/home/:homeId/qr',
          builder: (context, state) {
            final homeId = int.tryParse(state.pathParameters['homeId'] ?? '');
            return QRCodeViewScreen(homeId: homeId ?? 0);
          },
        ),
        GoRoute(
          path: '/home/:homeId/invite',
          builder: (context, state) {
            final homeId = int.tryParse(state.pathParameters['homeId'] ?? '');
            return InviteLinkScreen(homeId: homeId ?? 0);
          },
        ),
        GoRoute(
          path: '/home/:homeId/invite',
          builder: (context, state) {
            final homeId = int.tryParse(state.pathParameters['homeId'] ?? '');
            return InviteScreen(homeId: homeId ?? 0);
          },
        ),
        GoRoute(
          path: '/create-chore',
          builder: (context, state) => const CreateChoreScreen(),
        ),
      ],
    );
  }
}
