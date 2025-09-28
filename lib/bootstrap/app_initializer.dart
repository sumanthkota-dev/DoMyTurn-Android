import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:domyturn/core/storage/secure_storage_service.dart';
import 'package:domyturn/features/auth/data/repositories/auth_repository.dart';
import 'package:domyturn/features/auth/data/repositories/user_repository.dart';
import 'package:domyturn/shared/service/notification_service.dart';
import 'package:domyturn/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../../core/session/app_session.dart';
import '../core/routes/global_navigation.dart';

final logger = Logger(printer: PrettyPrinter());

class AppInitializer {
  /// 🌐 Initialize Firebase, local notifications, and FCM
  static Future<void> initialize() async {
    await dotenv.load(); // no path needed now
    await _initializeFirebase();
    await _initializeNotifications();
    await _logFcmToken();

    // 🧠 Load tokens into memory and refresh if needed
    await AppSession.instance.initialize();
  }

  /// 🚀 Initializes Firebase and permissions
  static Future<void> _initializeFirebase() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseMessaging.instance.requestPermission();
  }

  /// 🔔 Initialize local + FCM notifications
  /// 🔔 Initialize local + FCM notifications
  static Future<void> _initializeNotifications() async {
    await NotificationService.initialize();

    FirebaseMessaging.onMessage.listen(NotificationService.showNotification);

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationNavigation(message);
    });

    // ✅ Also handle app opened from terminated state
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationNavigation(initialMessage);
    }
  }

  /// 🧭 Handle navigation on notification tap
  static void _handleNotificationNavigation(RemoteMessage message) {
    final route = message.data['route'];
    final context = navigatorKey.currentContext;

    if (route != null && context != null) {
      logger.i("🔔 Navigating to: $route from notification tap");
      GoRouter.of(context).go(route); // ✅ Use this instead of context.go()
    } else {
      logger.w("🔔 Notification tap received but no valid route provided.");
    }
  }


  /// 📬 Log and save FCM token
  static Future<void> _logFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        logger.i("📬 FCM Token Generated");

        // ✅ Save in AppSession
        await AppSession.instance.setFcmToken(token);

        // ✅ Save to Secure Storage
        await SecureStorageService().writeValue("fcm_token", token);
      } else {
        logger.w("⚠️ FCM Token is null (likely iOS simulator or not available)");
      }
    } catch (e, st) {
      logger.e("🔥 Failed to get FCM token", error: e, stackTrace: st);
    }
  }

  /// 🔑 Route user based on session and home presence
  static Future<String> determineInitialRoute() async {
    final storage = SecureStorageService();
    final authRepo = AuthRepository();
    final userRepo = UserRepository();

    final userIdStr = await storage.readValue("userId");
    if (userIdStr == null) return '/login';

    try {
      final userId = int.tryParse(userIdStr);
      if (userId == null) return '/login';

      final authUser = await authRepo.isUserVerified(userId);
      if (authUser == null) return '/login';

      if (!authUser.isVerified) {
        await authRepo.sendOtp(authUser.email);
        return '/otp?email=${Uri.encodeComponent(authUser.email)}&sent=true'; // ✅ FIXED
      }

      final isInHome = await userRepo.isUserInHome();
      return isInHome ? '/dashboard' : '/create-or-join-home';
    } catch (e, st) {
      logger.e("Routing error: $e\n$st");
      return '/login';
    }
  }
}
