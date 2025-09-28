import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> writeValue(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> readValue(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> deleteValue(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

}
