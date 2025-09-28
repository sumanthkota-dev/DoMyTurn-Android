import 'package:dio/dio.dart';
import 'package:domyturn/features/auth/data/models/home_update_model.dart';
import 'package:logger/logger.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/session/app_session.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/absent_user_model.dart';
import '../models/home_model.dart';

class HomeRepository {
  final Dio _dio = DioClient().dio;
  final SecureStorageService _storage = SecureStorageService();
  final logger = Logger(printer: PrettyPrinter());

  Future<bool> createHome(
      String name, {
        required String address,
        String? city,
        String? district,
        String? state,
        String? country,
        String? pincode,
      }) async {
    try {
      final response = await _dio.post(
        '/home/create',
        data: {
          'name': name,
          'address': address,
          'city': city,
          'district': district,
          'state': state,
          'country': country,
          'pincode': pincode,
        },
      );

      if (response.statusCode == 201) {
        final homeId = response.data;
        await AppSession.instance.setHomeId(homeId);
        return true;
      } else {
        logger.i('Failed to create home: ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final message = e.response?.data['error'] ?? e.message;
      logger.e('Dio error ($status): $message');
      return false;
    } catch (e) {
      logger.e('Unexpected error creating home: $e');
      return false;
    }
  }

  Future<String> updateHome(HomeUpdateDto home) async {
    final homeId = await _storage.readValue('homeId');
    if (homeId == null) throw Exception("Home ID not found");
    final response = await _dio.put('/home/update', data:
    {
      "homeId":homeId,
      "name": home.name,
      "address": home.address,
      "city": home.city,
      "district": home.district,
      "state": home.state,
      "country": home.country,
      "pincode": home.pincode,
    });
    return response.data.toString();
  }

  Future<bool> joinHome(String inviteCode) async {
    try {
      final response = await _dio.post('/home/join/$inviteCode');

      if (response.statusCode == 200) {
        final homeId = response.data['homeId'];

        if (homeId != null) {
          await AppSession.instance.setHomeId(homeId);
          return true;
        } else {
          logger.w('Join success but no homeId in response');
          return false;
        }
      } else {
        logger.i('Failed to join home: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      logger.e('Error joining home: $e');
      return false;
    }
  }


  Future<Response> fetchQrCode(int homeId) async {
    try {
      final response = await _dio.get(
        '/home/$homeId/qr',
        options: Options(responseType: ResponseType.bytes),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> fetchInviteLink(int homeId) async {
    try {
      final response = await _dio.get('/home/$homeId/invite-link');
      return response.data['inviteLink'];
    } catch (e) {
      logger.e('Error fetching invite link: $e');
      return null;
    }
  }

  Future<Home> fetchHomeDetails() async {
    final homeId = await _storage.readValue('homeId');
    if (homeId == null) throw Exception("Home ID not found");
    try{
      final response = await _dio.get('/home/get/$homeId');
      return Home.fromJson(response.data);
    }
    catch (e, stack) {
      logger.e(e);
      logger.e(stack);
      rethrow;
    }
  }

  Future<void> markUserAbsent() async {
    final homeId = await _storage.readValue('homeId');
    final response = await _dio.post('/home/$homeId/absent');
    logger.i("Response : "+response.statusCode.toString());
    if (response.statusCode != 200) {
      throw Exception('Failed to mark user as absent');
    }
  }

  Future<String> fetchAbsenceStatus() async {
    final userId = await _storage.readValue('userId');
    final response = await _dio.get('/home/absence/status/$userId');
    logger.i(response.toString());
    return  response.data.toString(); // "PRESENT", etc.
  }

  Future<String> cancelUserAbsent() async{
    final userId = await _storage.readValue('userId');
    final response = await _dio.get('/home/update/absence/$userId');
    logger.i(response.toString());
    return  response.data.toString(); //
  }

  Future<List<int>> fetchPendingUserIds(int homeId) async {
    final response = await _dio.get('/home/pending/users/$homeId');
    logger.i("Pending User : "+response.toString());
    final List<dynamic> ids = response.data;
    return ids.cast<int>(); // Convert to List<int>
  }

  Future<void> approveAbsence(int userId) async {
    final homeId = await _storage.readValue('homeId');
    if (homeId == null) throw Exception("Home ID not found");
    final response = await _dio.post('/home/absence/approve/$userId/$homeId');
    logger.i("Absence approved: ${response.statusCode} ${response.data}");
  }

  Future<Set<int>> fetchAbsentUserIds() async {
    try {
      final homeId = await _storage.readValue('homeId');
      if (homeId == null) throw Exception("Home ID not found");
      final response = await _dio.get('/home/absids/$homeId');
      final List<dynamic> data = response.data;
      return data.map((e) => e as int).toSet();
    } catch (e) {
      throw Exception("Failed to fetch absent user IDs: $e");
    }
  }

  Future<List<AbsentUser>> fetchAbsentUsers() async {
    try {
      final homeId = await _storage.readValue('homeId');
      if (homeId == null) throw Exception("Home ID not found");

      final response = await _dio.get('/home/absusrs/$homeId');
      final List<dynamic> data = response.data;

      return data.map((e) => AbsentUser.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch absent users: $e');
    }
  }

  Future<void> leaveHome() async {
    try {
      final homeId = await _storage.readValue('homeId');
      if (homeId == null) throw Exception("Home ID not found");

      final response = await _dio.delete('/home/leave/$homeId');
      if (response.statusCode != 200) {
        throw Exception("Failed to leave home: ${response.data}");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteHome() async {
    final homeId = await _storage.readValue('homeId');
    if (homeId == null) throw Exception("Home ID not found");

    final response = await _dio.delete('/home/delete/$homeId');
    if (response.statusCode != 200) {
      throw Exception("Failed to delete home: ${response.data}");
    }
  }

  Future<void> assignNewCreator(int creatorId) async {
    final homeId = await _storage.readValue('homeId');
    if (homeId == null) throw Exception("Home ID not found");

    final response = await _dio.post('/home/$homeId/assign/$creatorId');
    if (response.statusCode != 200) {
      throw Exception("Failed to assign new home creator: ${response.data}");
    }
  }
}
