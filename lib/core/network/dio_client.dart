import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../features/auth/data/models/auth_response.dart';
import '../../features/auth/data/models/error_info.dart';
import '../../shared/utils/global_scaffold.dart';
import '../routes/global_navigation.dart';
import '../session/app_session.dart';
import 'lock.dart';
import 'retry_iterceptor.dart';

final Logger logger = Logger(printer: PrettyPrinter());

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  final Lock _refreshTokenLock = Lock();
  late final Dio _dio;

  Dio get dio => _dio;

  DioClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _getBaseUrl(),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
    ));

    _dio.interceptors.addAll([
      _authInterceptor(),
      RetryInterceptor(dio: _dio, maxRetries: 3, retryDelay: const Duration(seconds: 2)),
    ]);
  }

  // String _getBaseUrl() {
  //   if (kIsWeb) return 'http://localhost:8080/api';
  //   if (Platform.isAndroid) return 'http://10.0.2.2:8080/api';
  //   return 'http://localhost:8080/api';
  // }

  String _getBaseUrl() {
    // if (kIsWeb) {
    //   return 'http://localhost:8080/api';
    // }
    //
    // if (Platform.isAndroid) {
    //   return _isAndroidEmulator()
    //       ? 'http://10.0.2.2:8080/api'
    //       : 'http://192.168.29.24:8080/api'; // Replace with your local IP
    // }
    // return 'http://192.168.29.24:8080/api';
    // iOS and others
    return 'https://domyturn.app/api'; // Same IP used for iOS devices
  }


  bool _isAndroidEmulator() {
    return !Platform.isIOS &&
        (Platform.environment['ANDROID_EMULATOR_BUILD'] != null ||
            Platform.environment['ANDROID_PRODUCT']?.contains('sdk') == true);
  }


  late bool _isEmulator;

  Future<void> detectEmulator() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      _isEmulator = androidInfo.isPhysicalDevice == false;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      _isEmulator = iosInfo.isPhysicalDevice == false;
    } else {
      _isEmulator = false;
    }
  }

  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
        onRequest: (options, handler) async {
          final isPublic = options.extra['isPublic'] == true;

          if (isPublic) {
            // 🚫 Skip token logic for public endpoints
            return handler.next(options);
          }

          final session = AppSession.instance;

          // ⛓ Centralize initialization + expiry check inside the lock
          await _refreshTokenLock.synchronized(() async {
            if (session.accessToken == null || session.accessTokenExpiry == null) {
              await session.initialize();
            }

            if (session.isAccessTokenExpired) {
              logger.i("💡 🔁 Access token expired. Trying to refresh...");
              final refreshed = await _refreshToken();

              if (!refreshed) {
                logger.w("❌ Token refresh failed during request setup");
                await session.clear();
              }
            }
          });

          // ✅ Add token after possible refresh
          if (session.accessToken != null) {
            options.headers['Authorization'] = 'Bearer ${session.accessToken}';
          }

          handler.next(options);
        },
        onError: (DioException err, handler) async {
          final statusCode = err.response?.statusCode;
          final path = err.requestOptions.path;
          final isUnauthorized = statusCode == 401 || statusCode == 403;
          final isRefreshEndpoint = path.contains('/auth/public/refresh-token');
          final alreadyRetried = err.requestOptions.extra['retry'] == true;

          final data = err.response?.data;

          // 🔥 Handle 500 Internal Server Error — no retry
          if (statusCode == 500) {
            String? message;

            try {
              if (data is Map<String, dynamic>) {
                final error = ErrorInfo.fromJson(data);
                message = error.errorMessage;
              }
            } catch (e) {
              logger.e("🔥 Failed to parse ErrorInfo: $e");
            }

            message ??= "Something went wrong. Please try again later.";
            logger.w("🔥 Server error: $message");
            GlobalScaffold.showSnackbar(message, type: SnackbarType.error);

            return handler.next(err); // Don't retry on 500
          }

          // 🔁 Handle 401/403 (Token Refresh)
          if (isUnauthorized && !isRefreshEndpoint && !alreadyRetried) {
            logger.w("🔁 Unauthorized. Attempting token refresh...");

            final refreshed = await _refreshTokenLock.synchronized(() async {
              return await _refreshToken();
            });

            if (refreshed) {
              final session = AppSession.instance;
              final retryOptions = err.requestOptions
                ..headers['Authorization'] = 'Bearer ${session.accessToken}'
                ..extra['retry'] = true;

              try {
                final response = await _dio.fetch(retryOptions);
                return handler.resolve(response);
              } catch (e) {
                logger.e("🔁 Retry after refresh failed: $e");
                await AppSession.instance.clear();
                redirectToLogin();
                return;
              }
            } else {
              logger.e("⛔ Refresh failed. Clearing session.");
              await AppSession.instance.clear();
              redirectToLogin();
              return;
            }
          }

          // ✅ Other errors: try parsing and showing custom message if present
          if (data is Map<String, dynamic>) {
            try {
              final error = ErrorInfo.fromJson(data);
              if (error.errorMessage.isNotEmpty) {
                GlobalScaffold.showSnackbar(error.errorMessage, type: SnackbarType.error);
              }
            } catch (e) {
              logger.e("⚠️ Failed to parse ErrorInfo: $e");
            }
          }

          return handler.next(err); // Proceed with default error propagation
        }
    );
  }


  Future<bool> _refreshToken() async {
    final session = AppSession.instance;
    final refreshToken = session.refreshToken;
    // logger.i("🧪 Checking refresh eligibility...");
    // logger.i("🔐 Current refresh token: $refreshToken");
    // logger.i("⏰ Refresh token expiry: ${session.refreshTokenExpiry}");
    // logger.i("⏰ isRefreshTokenExpired: ${session.isRefreshTokenExpired}");
    if (refreshToken == null || session.isRefreshTokenExpired) {
      logger.w("❌ Refresh token is missing or expired");
      return false;
    }
    logger.i("🚀 Hitting refresh-token endpoint...");
    try {
      final refreshDio = Dio(BaseOptions(baseUrl: _getBaseUrl()));

      final response = await refreshDio.post(
        '/auth/public/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      // logger.i("🔁 Refresh response: ${response.data}");

      if (response.statusCode == 200 && response.data['accessToken'] != null) {
        final newAccessToken = response.data['accessToken'];
        final accessTokenExpiry = int.parse(response.data['accessTokenExpiry'].toString());
        final userId = int.parse(response.data['userId'].toString());

        session.setTokens(
          newAccessToken,
          refreshToken,
          accessTokenExpiry,
          session.refreshTokenExpiry!,
        );

        await session.persistTokens(AuthResponse(
          accessToken: newAccessToken,
          accessTokenExpiry: accessTokenExpiry,
          refreshToken: refreshToken,
          refreshTokenExpiry: session.refreshTokenExpiry!,
          userId: userId,
        ));

        logger.i("✅ Tokens refreshed and saved");
        return true;
      } else {
        logger.w("⚠️ Refresh call succeeded but no token in response");
      }
    } catch (e, stack) {
      logger.e("🚨 Exception during token refresh: $e", error: e, stackTrace: stack);
    }

    return false;
  }
}
