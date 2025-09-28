import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/chore_model.dart';

class ChoresRepository {
  final Dio _dio = DioClient().dio;
  final SecureStorageService _storage = SecureStorageService();

  Future<bool> createTask(Chore chore) async {
    logger.i("Chore : ${chore.toJsonString()}");
    try {
      final response = await _dio.post('/tasks/create', data: chore.toJson());
      logger.i("✅ Create response: ${response.data}");
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        logger.w("⚠️ Bad request: ${e.response?.data}");
        return false; // Don't crash, global interceptor can still show snackbar
      }
      rethrow; // Other unhandled errors go to global handler
    }
  }


  Future<List<Chore>> fetchTasks() async {
    final homeId = await _storage.readValue('homeId');
    if (homeId == null) throw Exception("Home ID not found");

    try {
      final response = await _dio.get('/tasks/$homeId/home-tasks');
      return (response.data as List)
          .map((e) => Chore.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception("Failed to load tasks: $e");
    }
  }

  Future<void> markTaskDone(int taskId) async {
    final homeId = await _storage.readValue('homeId');
    if (homeId == null) throw Exception("Home ID not found");

    try {
      final response = await _dio.put('/tasks/$taskId/$homeId/done');
      if (response.statusCode != 200) {
        throw Exception("Failed to mark task as done: ${response.data}");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTask(int taskId) async {
    try {
      final response = await _dio.delete('/tasks/delete-task/$taskId');
      if (response.statusCode != 200) {
        throw Exception("Failed to delete chore: ${response.data}");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Chore> fetchTaskById(int taskId) async {
    try {
      final response = await _dio.get('/tasks/$taskId/task');
      return Chore.fromJson(response.data);
    } catch (e) {
      throw Exception("Failed to fetch task: $e");
    }
  }

  Future<void> updateTask(Map<String, dynamic> dto) async {
    if (dto['id'] == null) throw Exception("Task ID is null");
    logger.i("Chore Updated : "+dto.toString());
    try {
      final response = await _dio.put(
        '/tasks/${dto['homeId']}/update',
        data: dto,
      );
      logger.i('Update Response: ${response.statusCode}');
      if (response.statusCode != 200) {
        throw Exception('Failed to update task: ${response.data}');
      }
    } catch (e) {
      logger.e("Error updating task: $e");
      rethrow;
    }
  }
}
