import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_profile_model.dart';
import '../utils/env_config.dart';
import '../utils/api_endpoints.dart';
import '../utils/api_response.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  final String _baseUrl = EnvConfig.apiBaseUrl;

  factory UserService() {
    return _instance;
  }

  UserService._internal();

  Future<ApiResponse<UserProfileData>> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiEndpoints.me}'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(
          UserProfileData.fromJson(data['data']),
          message: data['message'] ?? 'Success',
        );
      } else {
        final error = json.decode(response.body);
        return ApiResponse.error(
          error['message'] ?? 'Failed to get user profile',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<UserProfileData>> updateProfile(
      UserProfileData profile) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl${ApiEndpoints.updateProfile}'),
        headers: await _getHeaders(),
        body: json.encode(profile.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(
          UserProfileData.fromJson(data['data']),
          message: data['message'] ?? 'Profile updated successfully',
        );
      } else {
        final error = json.decode(response.body);
        return ApiResponse.error(
          error['message'] ?? 'Failed to update profile',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<String>> uploadProfileImage(File image) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl${ApiEndpoints.uploadProfileImage}'),
      );

      request.headers.addAll(await _getHeaders());
      request.files.add(
        await http.MultipartFile.fromPath('image', image.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(
          data['data']['imageUrl'],
          message: data['message'] ?? 'Image uploaded successfully',
        );
      } else {
        final error = json.decode(response.body);
        return ApiResponse.error(
          error['message'] ?? 'Failed to upload image',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getDashboardData() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiEndpoints.dashboard}'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(
          data['data'],
          message: data['message'] ?? 'Success',
        );
      } else {
        final error = json.decode(response.body);
        return ApiResponse.error(
          error['message'] ?? 'Failed to get dashboard data',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
    };

    // Add authorization header if token exists
    final token = await _getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<String?> _getToken() async {
    // Implement token retrieval logic here
    return null;
  }
}
