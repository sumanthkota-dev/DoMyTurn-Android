import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/session/app_session.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/shopping_item_model.dart';
import '../models/shopping_list_update.dart';

class ShoppingRepository {
  final Dio _dio = DioClient().dio;
  final SecureStorageService _storage = SecureStorageService();
  final logger = Logger(printer: PrettyPrinter());

  Future<List<ShoppingItem>> fetchUnboughtItems() async {
    final homeId = await _storage.readValue('homeId');

    try {
      final response = await _dio.get('/shopping/get/$homeId');
      final List<dynamic> jsonList = response.data;
      return jsonList.map((json) => ShoppingItem.fromJson(json)).toList();
    } on DioException catch (e) {
      logger.e("Fetch error: ${e.response?.statusCode} ${e.response?.data}");
      throw Exception('Failed to load shopping items');
    }
  }

  Future<List<ShoppingItem>> fetchBoughtItems() async {
    final homeId = await AppSession.instance.homeId;
    final response = await _dio.get(
      '/shopping/get/bought/$homeId');
    return (response.data as List).map((json) => ShoppingItem.fromJson(json)).toList();
  }

  Future<void> createItem(ShoppingItem shoppingItem) async {
    try {
      final response = await _dio.post(
        '/shopping/create',
        data: shoppingItem.toJson(),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to create item: ${response.data}");
      }
    } on DioException catch (e) {
      throw Exception("Failed to create item: ${e.response?.data ?? e.message}");
    }
  }


  Future<void> markAsBought(ShoppingListUpdate update) async {
    try{
      final response = await _dio.put(
          '/shopping/bought',data: update);
      if (response.statusCode != 200) {
        throw Exception("Failed to mark as bought: ${response.data}");
      }
  } on DioException catch (e) {
  throw Exception("Mark as bought failed: ${e.response?.data ?? e.message}");
  }
  }


  Future<void> deleteItem(int id) async {
    try {
      final response = await _dio.delete('/shopping/delete/$id');
      if (response.statusCode != 204) {
        throw Exception("Failed to delete shopping list: ${response.data}");
      }
    } on DioException catch (e) {
      logger.e("EXCEPTION while deleting: $e");
      throw Exception("Delete failed: ${e.response?.data ?? e.message}");
    }
  }

  Future<void> updateItem(ShoppingItem item) async {
    try {
      final response = await _dio.put(
        '/shopping/add/list',
        data: item.toJson(),
      );
      if (response.statusCode != 200) {
        throw Exception("Failed to update item: ${response.data}");
      }
    } on DioException catch (e) {
      throw Exception("Update failed: ${e.response?.data ?? e.message}");
    }
  }

}
