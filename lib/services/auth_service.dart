import 'package:gohealth/models/auth_model.dart';
import 'package:gohealth/models/api_response_model.dart';
import 'package:gohealth/utils/dio_client.dart';

class AuthService {
  final DioClient _dioClient = DioClient();

  Future<ApiResponse<AuthResponseData>> login(
      String email, String password) async {
    try {
      final response = await _dioClient.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      return ApiResponse<AuthResponseData>.fromJson(
        response.data,
        (json) => AuthResponseData.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<ApiResponse<AuthResponseData>> register(
      String name, String email, String password) async {
    try {
      final response = await _dioClient.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      return ApiResponse<AuthResponseData>.fromJson(
        response.data,
        (json) => AuthResponseData.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<ApiResponse<AuthResponseData>> refreshToken(
      String refreshToken) async {
    try {
      final response = await _dioClient.post(
        '/auth/refresh',
        data: {
          'refreshToken': refreshToken,
        },
      );

      return ApiResponse<AuthResponseData>.fromJson(
        response.data,
        (json) => AuthResponseData.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<ApiResponse<dynamic>> logout() async {
    try {
      final response = await _dioClient.post('/auth/logout');
      return ApiResponse<dynamic>.fromJson(
        response.data,
        (json) => null,
      );
    } catch (e) {
      rethrow;
    }
  }
}
