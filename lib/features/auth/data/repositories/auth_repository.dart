import 'package:dio/dio.dart';
import 'package:domyturn/features/auth/data/models/user_model.dart';
import 'package:domyturn/features/auth/data/repositories/notification_repository.dart';
import 'package:logger/logger.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/session/app_session.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../shared/service/app_local_notification_service.dart';
import '../models/auth_response.dart';
import '../models/auth_user_model.dart';
import '../models/otp_request.dart';
import '../models/refresh_response_model.dart';
import '../models/register_request.dart';

class AuthRepository {
  final Dio _dio = DioClient().dio;
  final logger = Logger(printer: PrettyPrinter());
  final NotificationRepository notificationRepository = NotificationRepository();

  Future<bool> registerUser(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        '/auth/public/register',
        data: request.toJson(),
        options: Options(
          extra: {'isPublic': true},
        ),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final userId = response.data['userId'];
        await AppSession.instance.setUserId(userId); // If needed
        return true;
      } else {
        logger.i(
            'Registration failed: ${response.statusCode} ${response.data}');
        return false;
      }
    } catch (e) {
      logger.e('Error during registration: $e');
      return false;
    }
  }

  Future<AuthUser?> isUserVerified(int userId) async {
    try {
      final response = await _dio.get('/auth/public/isverified/$userId',options: Options(
        extra: {'isPublic': true},
      ),);
      logger.i("verified : ${response.statusCode}");
      logger.i("Verified data : ${response.data}");
      if (response.statusCode == 200) {
        return AuthUser.fromJson(response.data);
      }
      return null;
    } catch (e) {
      logger.e('Failed to check verification: $e');
      return null;
    }
  }

  Future<bool> loginUser(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/public/login',
        data: {'email': email, 'password': password},
        options: Options(
          extra: {'isPublic': true},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        AppSession.instance.setTokens(
          data['accessToken'],
          data['refreshToken'],
          int.parse(data['accessTokenExpiry'].toString()),
          int.parse(data['refreshTokenExpiry'].toString()),
        );
        await AppSession.instance.persistTokens(AuthResponse(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          accessTokenExpiry: int.parse(data['accessTokenExpiry'].toString()),
          refreshTokenExpiry: int.parse(data['refreshTokenExpiry'].toString()),
          userId: int.parse(data['userId'].toString()),
        ));

        // Optionally store userId
        await AppSession.instance.setUserId(data['userId']);

        return true;
      }
      return false;
    } catch (e) {
      logger.e('⛔ Login error: $e');
      return false;
    }
  }

  Future<String> verifyOtp(OtpRequest otpRequest) async {
    try {
      final response = await _dio.post(
        '/auth/public/verify-user',
        data: otpRequest.toJson(),
        options: Options(
          extra: {'isPublic': true},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        AppLocalNotificationService.showNotification(
          title: "🎉 Welcome to DoMyTurn!",
          body: "Your account has been created successfully.",
        );
        AppSession.instance.setTokens(
          data['accessToken'],
          data['refreshToken'],
          int.parse(data['accessTokenExpiry'].toString()),
          int.parse(data['refreshTokenExpiry'].toString()),
        );
        await AppSession.instance.persistTokens(AuthResponse(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          accessTokenExpiry: int.parse(data['accessTokenExpiry'].toString()),
          refreshTokenExpiry: int.parse(data['refreshTokenExpiry'].toString()),
          userId: int.parse(data['userId'].toString()),
        ));

        return 'SUCCESS';
      } else {
        final errorMsg = response.data['errorMessage'] ?? 'UNKNOWN_ERROR';
        return errorMsg;
      }
    } on DioException catch (e) {
      logger.e('❌ DioException during verifyOtp: $e');

      if (e.response != null && e.response?.data != null) {
        final errorData = e.response!.data;
        final errorMsg = errorData['errorMessage'] ?? 'UNKNOWN_ERROR';
        return errorMsg;
      }

      return 'UNKNOWN_ERROR';
    } catch (e) {
      logger.e('❌ Unexpected error during verifyOtp: $e');
      return 'UNKNOWN_ERROR';
    }
  }


  Future<void> updateUserName(String newName) async {
    try {
      final response = await _dio.put('/auth/secure/update-name/$newName');
      logger.i(response.statusCode.toString());
      if (response.statusCode == 200) {
        final data = response.data;

        AppSession.instance.setTokens(
          data['accessToken'],
          data['refreshToken'],
          int.parse(data['accessTokenExpiry'].toString()),
          int.parse(data['refreshTokenExpiry'].toString()),
        );
        await AppSession.instance.persistTokens(AuthResponse(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          accessTokenExpiry: int.parse(data['accessTokenExpiry'].toString()),
          refreshTokenExpiry: int.parse(data['refreshTokenExpiry'].toString()),
          userId: int.parse(data['userId'].toString()),
        ));
      } else {
        throw Exception('Failed to update name');
      }
    } catch (e) {
      logger.e('Error updating name: $e');
      throw Exception('Failed to update name');
    }
  }

  Future<String> sendOtp(String email) async {
    try {
      logger.i("Sending Otp");
      final response = await _dio.post('/auth/public/send-otp/$email',options: Options(
        extra: {'isPublic': true},
      ),);
      logger.i("Otp Response : " + response.toString());
      final data = response.data.toString().toUpperCase();
      final code = response.statusCode ?? 500;

      if (code == 200 && data == "SUCCESS") return 'SUCCESS';
      if (code == 429 || data.contains("MAX_ATTEMPTS_REACHED"))
        return 'MAX_ATTEMPTS_REACHED';

      return 'ERROR';
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      final body = e.response?.data.toString().toUpperCase() ?? '';

      if (code == 429 || body.contains("MAX_ATTEMPTS_REACHED")) {
        return 'MAX_ATTEMPTS_REACHED';
      }

      return 'ERROR';
    } catch (e) {
      logger.e('❌ Unexpected Send OTP Error: $e');
      return 'ERROR';
    }
  }

  Future<void> updateEmail(String newEmail, String otp) async {
    try {
      final response = await _dio.put(
          '/auth/secure/update-email/$newEmail/$otp');
      logger.i('Update Email Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;

        // Set tokens in session
        AppSession.instance.setTokens(
          data['accessToken'],
          data['refreshToken'],
          int.parse(data['accessTokenExpiry'].toString()),
          int.parse(data['refreshTokenExpiry'].toString()),
        );

        // Persist tokens
        await AppSession.instance.persistTokens(AuthResponse(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          accessTokenExpiry: int.parse(data['accessTokenExpiry'].toString()),
          refreshTokenExpiry: int.parse(data['refreshTokenExpiry'].toString()),
          userId: int.parse(data['userId'].toString()),
        ));
      } else {
        throw Exception('Failed to update email');
      }
    } catch (e) {
      logger.e('Error updating email: $e');
      throw Exception('Failed to update email');
    }
  }


  Future<User> getUserById(int userId) async {
    final response = await _dio.get('/auth/public/get-user/$userId',options: Options(
      extra: {'isPublic': true},
    ),);
    return User.fromJson(response.data);
  }

  Future<AuthResponse?> refreshAccessToken(String refreshToken) async {
    try {
      final response = await _dio.post('/auth/public/refresh-token', data: {
        'refreshToken': refreshToken,
      },options: Options(
      extra: {'isPublic': true},
      ),);

      final data = response.data;

      return AuthResponse(
        accessToken: data['accessToken'],
        accessTokenExpiry: data['accessTokenExpiry'],
        refreshToken: refreshToken,
        // reuse existing
        refreshTokenExpiry: AppSession.instance.refreshTokenExpiry ?? 0,
        // reuse from memory
        userId: data['userId'],
      );
    } catch (e, st) {
      logger.e("⛔ Refresh token error: $e\n$st");
      return null;
    }
  }

  Future<String> changePasswordSecure(String oldPassword, String newPassword) async {
    try {
      final response = await _dio.post(
        '/auth/secure/change-password',
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode == 200) {
        return 'SUCCESS';
      }

      // You may get non-200s without triggering catch
      if (response.statusCode == 401) {
        return 'INVALID_OLD_PASSWORD';
      }

      return 'FAILED';
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) return 'INVALID_OLD_PASSWORD';
      logger.e("Password change DioException: $e");
      return 'ERROR';
    } catch (e) {
      logger.e("Password change unknown error: $e");
      return 'ERROR';
    }
  }


  Future<String> changePassword(String email, String newPassword) async {
    try {
      final response = await _dio.post(
        '/auth/public/change-password',
        data: {
          'email': email,
          'newPassword': newPassword,
        },
        options: Options(
          extra: {'isPublic': true},
        ),
      );

      if (response.statusCode == 200) {
        return 'SUCCESS';
      } else if (response.statusCode == 401) {
        return 'INVALID_OLD_PASSWORD';
      } else {
        return 'FAILED';
      }
    } catch (e) {
      logger.e("Password change error: $e");
      return 'ERROR';
    }
  }


  Future<String> verifyUserForPasswordReset(String email, String name) async {
    final response = await _dio.post('/auth/public/verify-reset', data: {
      'email': email,
      'name': name,
    },options: Options(
      extra: {'isPublic': true},
    ),);
    logger.i("Response : "+response.statusCode.toString());
    if (response.statusCode == 200) return 'VERIFIED';
    if (response.statusCode == 404) return 'NOT_FOUND';
    return 'ERROR';
  }

  Future<bool> deleteUser() async {
    try {
      final userId = AppSession.instance.userId;
      final response = await _dio.delete('/auth/secure/delete/$userId');
      logger.i(response.data.toString());
      if (response.statusCode == 200) {
        return true; // User deleted successfully
      }
      return false;
    } catch (e) {
      rethrow; // Let caller handle error
    }
  }
}


