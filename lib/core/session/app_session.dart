import 'package:domyturn/core/storage/secure_storage_service.dart';
import 'package:domyturn/features/auth/data/models/auth_response.dart';
import 'package:domyturn/features/auth/data/repositories/auth_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class AppSession extends ChangeNotifier{
  AppSession._internal();
  static final AppSession instance = AppSession._internal();
  factory AppSession() => throw UnimplementedError("Use AppSession.instance instead.");

  final SecureStorageService _storage = SecureStorageService();
  final AuthRepository _authRepository = AuthRepository();

  // 🧠 In-memory state
  String? accessToken;
  int? accessTokenExpiry;
  String? refreshToken;
  int? refreshTokenExpiry;
  String? fcmToken;

  int? _userId;
  int? _homeId;

  int? get homeId => _homeId;
  int? get userId => _userId;

  static const _kAccessToken = "accessToken";
  static const _kAccessTokenExpiry = "accessTokenExpiry";
  static const _kRefreshToken = "refreshToken";
  static const _kRefreshTokenExpiry = "refreshTokenExpiry";
  static const _kUserId = "userId";
  static const _kHomeId = "homeId";
  static const _kFcmToken = "fcmToken";

  /// 🔐 Load session from secure storage
  Future<void> initialize() async {
    logger.i("🧠 [Session Init]");

    accessToken = await _storage.readValue(_kAccessToken);
    refreshToken = await _storage.readValue(_kRefreshToken);
    accessTokenExpiry = int.tryParse(await _storage.readValue(_kAccessTokenExpiry) ?? '');
    refreshTokenExpiry = int.tryParse(await _storage.readValue(_kRefreshTokenExpiry) ?? '');
    _userId = int.tryParse(await _storage.readValue(_kUserId) ?? '');
    _homeId = int.tryParse(await _storage.readValue(_kHomeId) ?? '');
    fcmToken = await _storage.readValue(_kFcmToken);

    if ([accessToken, refreshToken, accessTokenExpiry, refreshTokenExpiry].contains(null)) {
      logger.w("❌ Missing session data. Skipping initialization.");
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    if (now >= accessTokenExpiry!) {
      if (now < refreshTokenExpiry!) {
        logger.i("🔁 Access token expired. Trying to refresh...");
        final newTokens = await _authRepository.refreshAccessToken(refreshToken!);
        if (newTokens != null) {
          await persistTokens(newTokens);
          logger.i("✅ Tokens refreshed and loaded into memory.");
        } else {
          logger.w("⚠️ Token refresh failed.");
        }
      } else {
        logger.w("❌ Both access and refresh tokens expired.");
      }
    } else {
      logger.i("✅ Session loaded from storage.");
    }
  }

  /// 💾 Save new tokens
  Future<void> persistTokens(AuthResponse tokens) async {
    await _storage.writeValue(_kAccessToken, tokens.accessToken);
    await _storage.writeValue(_kAccessTokenExpiry, tokens.accessTokenExpiry.toString());

    if (tokens.refreshToken != null) {
      await _storage.writeValue(_kRefreshToken, tokens.refreshToken!);
    }

    if (tokens.refreshTokenExpiry != null) {
      await _storage.writeValue(_kRefreshTokenExpiry, tokens.refreshTokenExpiry.toString());
    }

    if (tokens.userId != null) {
      _userId = tokens.userId;
      await _storage.writeValue(_kUserId, _userId.toString());
    }

    setTokens(
      tokens.accessToken,
      tokens.refreshToken ?? refreshToken,
      tokens.accessTokenExpiry,
      tokens.refreshTokenExpiry ?? refreshTokenExpiry,
    );
  }

  /// ✅ Assign tokens in memory
  void setTokens(String access, String? refresh, int? accessExp, int? refreshExp) {
    accessToken = access;
    refreshToken = refresh;
    accessTokenExpiry = accessExp;
    refreshTokenExpiry = refreshExp;
  }

  /// 🧹 Clear session and secure storage
  Future<void> clear() async {
    _resetInMemory();
    notifyListeners();
    await _storage.deleteValue(_kAccessToken);
    await _storage.deleteValue(_kAccessTokenExpiry);
    await _storage.deleteValue(_kRefreshToken);
    await _storage.deleteValue(_kRefreshTokenExpiry);
    await _storage.deleteValue(_kUserId);
    await _storage.deleteValue(_kHomeId);
    await _storage.deleteValue(_kFcmToken);

    logger.i("🧼 AppSession cleared");
  }

  /// 🔁 Helper to reset in-memory vars
  void _resetInMemory() {
    accessToken = null;
    refreshToken = null;
    accessTokenExpiry = null;
    refreshTokenExpiry = null;
    _userId = null;
    _homeId = null;
    fcmToken = null;
  }

  /// 🏠 Save Home ID
  Future<void> setHomeId(dynamic homeId) async {
    logger.i("⛔ setHomeId called with: $homeId (${homeId.runtimeType})");
    final parsed = int.tryParse(homeId.toString());
    logger.i("📦 Parsed value: $parsed");
    if (parsed != null) {
      _homeId = parsed;
      await _storage.writeValue(_kHomeId, parsed.toString());
      logger.i("🏠 Saved homeId: $_homeId");
    } else {
      _homeId = null;
      await _storage.deleteValue(_kHomeId);
      logger.w("⚠️ Failed to save homeId: $homeId");
    }
    notifyListeners();
  }

  Future<void> clearHomeId() async {
    _homeId = null;
    notifyListeners();
    await _storage.deleteValue('homeId');
  }


  /// 👤 Save User ID
  Future<void> setUserId(dynamic userId) async {
    _userId = int.tryParse(userId.toString());
    if (_userId != null) {
      await _storage.writeValue(_kUserId, _userId.toString());
      logger.i("👤 Saved userId: $_userId");
    } else {
      logger.w("⚠️ Failed to save userId: $userId");
    }
  }

  /// 🔔 Save FCM Token
  Future<void> setFcmToken(String token) async {
    fcmToken = token;
    await _storage.writeValue(_kFcmToken, token);
    logger.i("📲 Saved FCM token");
  }

  /// 🔍 Token status checks
  bool get isAccessTokenExpired {
    final now = DateTime.now().millisecondsSinceEpoch;
    return accessToken == null || accessTokenExpiry == null || now >= accessTokenExpiry!;
  }

  bool get isRefreshTokenExpired {
    final now = DateTime.now().millisecondsSinceEpoch;
    return refreshToken == null || refreshTokenExpiry == null || now >= refreshTokenExpiry!;
  }
}
