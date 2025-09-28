import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';
import '../models/chore_model.dart';
import '../models/activity_model.dart';
import '../models/shopping_item_model.dart';

class DashboardRepository {
  final Dio _dio = DioClient().dio;
  final SecureStorageService _storage = SecureStorageService();
  final logger = Logger(printer: PrettyPrinter());

  Future<List<User>> fetchHomeMembers() async {
    final homeId = await _storage.readValue('homeId');
    if (homeId == null) throw Exception("Home ID not found in storage");

    try {
      final response = await _dio.get('/user/public/get/$homeId',options: Options(
        extra: {'isPublic': true},
      ),);
      final List<dynamic> data = response.data;
      final basicUsers = data.map((e) => User.fromJson(e)).toList();
      return basicUsers;
    } catch (e) {
      throw Exception("Failed to load home users: $e");
    }
  }


  Future<List<Chore>> fetchUserChores() async {
    final homeId = await _storage.readValue('homeId');
    if (homeId == null) throw Exception("Home ID not found in storage");

    try {
      final response = await _dio.get('/tasks/$homeId/user-tasks');
      final List<dynamic> data = response.data;
      return data.map((e) => Chore.fromJson(e)).toList();
    } catch (e) {
      throw Exception("Failed to load user chores: $e");
    }
  }

  Future<List<Activity>> fetchRecentActivities() async {
    final homeId = await _storage.readValue('homeId');
    if (homeId == null) throw Exception("Home ID not found in storage");

    try {
      final response = await _dio.get('/notification/$homeId');
      final List<dynamic> data = response.data;
      return data.map((e) => Activity.fromJson(e)).toList();
    } catch (e) {
      throw Exception("Failed to load activities: $e");
    }
  }

  Future<List<ShoppingItem>> fetchShoppingItems() async {
    final homeId = await _storage.readValue('homeId');
    if (homeId == null) throw Exception("Home ID not found in storage");

    try {
      final response = await _dio.get('/shopping/get/$homeId');
      final List<dynamic> data = response.data;
      return data.map((e) => ShoppingItem.fromJson(e)).toList();
    } catch (e) {
      throw Exception("Failed to load shopping items: $e");
    }
  }
}
