import 'package:dio/dio.dart';
import 'package:domyturn/features/auth/data/repositories/notification_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/session/app_session.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

class UserRepository {
  final Dio _dio = DioClient().dio;
  final SecureStorageService _storageService = SecureStorageService();
  final NotificationRepository notificationRepository = NotificationRepository();
  final logger = Logger(printer: PrettyPrinter());

  Future<bool> isUserInHome() async {
    try {
      final response = await _dio.get('/user/secure/user-has-home');
      logger.i("Code : "+response.statusCode.toString());
      if(response.statusCode==200)
        {
          final homeId = response.data;
          logger.i("HomeiD : "+homeId.toString());
          if (homeId != null && homeId != 0) {
            await AppSession.instance.setHomeId(homeId);
            return true;
          }
        }
      return false;
    } catch (e) {
      logger.e('Error checking if user is in home: $e');
      return false;
    }
  }

  Future<User> fetchUserDetails() async {
    final userId = await _storageService.readValue('userId');
    if (userId == null) throw Exception('User ID not found');

    final response = await _dio.get('/user/secure/get-user/$userId');
    return User.fromJson(response.data);
  }

  Future<User> fetchUser(int userId) async {
    final response = await _dio.get('/user/secure/get-user/$userId');
    return User.fromJson(response.data);
  }

  Future<void> updateUser(User user) async {
    final userId = await _storageService.readValue('userId');
    if (userId == null) throw Exception('User ID not found');

    final response = await _dio.put(
      '/user/secure/update/$userId',
      data: {
        'gender': user.gender,
        'dateOfBirth': user.dateOfBirth?.toIso8601String(),
        'mobile' : user.mobile,
        'address': user.address,
        'city': user.city,
        'country': user.country,
        'avatarSvg': user.avatarSvg,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update user');
    }
  }

  Future<List<User>> fetchUsers() async {
    final homeId = await _storageService.readValue('homeId');
    if (homeId == null) throw Exception('Home ID not found');

    final response = await _dio.get('/user/public/get/$homeId',options: Options(
      extra: {'isPublic': true},
    ),);
    return (response.data as List)
        .map((json) => User.fromJson(json))
        .toList();
  }

  Future<List<User>> fetchUsersInOrder(List<int> assignees, Set<int> completedUsers) async {
    final payload = {
      'assignees': assignees,
      'completedUsers': completedUsers.toList(),
    };
    logger.i("fetchUsersInOrder : "+payload.toString());
    final response = await _dio.post('/user/secure/user-order', data: payload);
    return (response.data as List)
        .map((json) => User.fromJson(json))
        .toList();
  }

  Future<void> sendFcmToken() async {
    final userIdStr = await _storageService.readValue('userId');
    if (userIdStr == null) {
      logger.w("⚠️ userId is null in secure storage");
      return;
    }

    final userId = int.tryParse(userIdStr);
    if (userId == null) {
      logger.e("❌ Failed to parse userId from string: $userIdStr");
      return;
    }

    String? fcmToken = await _storageService.readValue('fcm_token');

    if (fcmToken == null) {
      logger.w("⚠️ fcmToken is null in secure storage, trying to refresh...");
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await _storageService.writeValue('fcm_token', fcmToken);
          logger.i("🔁 FCM token refreshed and saved");
        } else {
          logger.e("❌ Failed to retrieve FCM token from Firebase");
          return;
        }
      } catch (e, stack) {
        logger.e("🔥 Error refreshing FCM token: $e", stackTrace: stack);
        return;
      }
    }

    try {
      await notificationRepository.sendTokenToBackend(userId: userId, token: fcmToken);
      logger.i("✅ FCM token sent to backend for userId=$userId");
    } catch (e, stack) {
      logger.e("🚨 Error sending FCM token: $e", stackTrace: stack);
    }
  }

  Future<List<User>> fetchAbsentUsersInHome(int homeId, List<int> userIds) async {
    final response = await _dio.post(
      '/user/secure/byIds/$homeId',
      data: userIds,
    );
    logger.i("UserSAbsent:"+response.statusCode.toString());
    return (response.data as List).map((json) => User.fromJson(json)).toList();
  }
}
