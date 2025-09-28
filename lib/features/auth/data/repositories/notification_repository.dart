import 'package:dio/dio.dart';
import 'package:domyturn/core/network/dio_client.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';

import '../models/push_notification_model.dart';

final logger = Logger(
  printer: PrettyPrinter(),
);
class NotificationRepository {
  final Dio _dio = DioClient().dio;

  Future<void> sendNotification(PushNotification notification) async {
    try {
      final response = await _dio.post(
        '/api/notification/send',
        data: notification.toJson(),
      );

      if (response.statusCode == 200) {
        logger.i('✅ Notification sent successfully: ${response.data}');
      } else {
        logger.i('⚠️ Failed to send notification: ${response.statusCode}');
      }
    } catch (e) {
      logger.i('❌ Error sending notification: $e');
    }
  }

  Future<void> initFCMToken({required int userId}) async {
    try {
      // Request permissions (important on iOS)
      await FirebaseMessaging.instance.requestPermission();

      String? token = await _getTokenWithRetry();

      if (token != null) {
        await sendTokenToBackend(userId: userId, token: token);
      } else {
        logger.w("⚠️ Failed to get FCM token after retries.");
      }

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        logger.i("🔄 Token refreshed: $newToken");
        sendTokenToBackend(userId: userId, token: newToken);
      });
    } catch (e) {
      logger.e("🔥 Error initializing FCM: $e");
    }
  }

  Future<String?> _getTokenWithRetry({int retries = 3, Duration delay = const Duration(seconds: 2)}) async {
    for (int i = 0; i < retries; i++) {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) return token;

      logger.w("🚧 Token null on attempt ${i + 1}, retrying...");
      await Future.delayed(delay);
    }
    return null;
  }

  Future<void> sendTokenToBackend({required int userId, required String token}) async {
    try {
      final response = await _dio.post("/notification/public/fcm-token", data: {
        "userId": userId,
        "fcmToken": token,
      },options: Options(
        extra: {'isPublic': true},
      ),);
      logger.i("✅ FCM token sent to backend: ${response.statusCode}");
    } catch (e) {
      logger.e("❌ Failed to send FCM token to backend: $e");
    }
  }

  Future<void> sendReminderToUser({
    required int userId,
    required String title,
  }) async {
    final message = "Reminder: Chore '$title' is still pending. Please take action.";

    try {
      final response = await _dio.post(
        '/notification/reminder/$userId',
        data: message,
        options: Options(
          headers: {'Content-Type': 'text/plain'},
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send reminder');
      }
    } catch (e) {
      debugPrint('Error sending reminder: $e');
      rethrow;
    }
  }
}
