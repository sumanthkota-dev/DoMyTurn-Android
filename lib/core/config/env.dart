// lib/core/config/env.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app_config.dart';

class Env {
  /// Call this in main() before runApp()
  static Future<void> load({String fileName = '.env'}) async {
    await dotenv.load(fileName: fileName);
  }

  static String get apiUrl => dotenv.env['API_URL'] ?? AppConfig.fallbackApiUrl;
  static String get environment => dotenv.env['ENV'] ?? AppConfig.defaultEnv;
  static String get appName => dotenv.env['APP_NAME'] ?? AppConfig.appName;
  static int get otpTimeout =>
      int.tryParse(dotenv.env['OTP_TIMEOUT'] ?? '') ?? AppConfig.defaultTimeout;

  // 🚀 Social Media
  static String get websiteUrl => dotenv.env['WEBSITE_URL'] ?? '';
  static String get facebookUrl => dotenv.env['FACEBOOK_URL'] ?? '';
  static String get instagramUrl => dotenv.env['INSTAGRAM_URL'] ?? '';
  static String get reviewUrl => dotenv.env['REVIEW_URL'] ?? '';
}
