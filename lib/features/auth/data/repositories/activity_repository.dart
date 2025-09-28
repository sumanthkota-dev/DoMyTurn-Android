import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/activity_model.dart';

class ActivityRepository {
  final Dio _dio = DioClient().dio;
  final SecureStorageService _storage = SecureStorageService();

  Future<List<Activity>> fetchActivities() async {
    final homeId = await _storage.readValue('homeId');
    if (homeId == null) {
      throw Exception("Home ID not found in storage");
    }

    try {
      final response = await _dio.get('/notification/$homeId');
      logger.i(response.statusCode.toString());
      final List<dynamic> data = response.data;

      return data.map((e) => Activity.fromJson(e)).toList();
    } catch (e) {
      throw Exception("Failed to load activities: $e");
    }
  }
}
