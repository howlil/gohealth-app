import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/profile_model.dart';
import '../models/api_response_model.dart';
import '../utils/env_config.dart';
import '../api/endpoints.dart';
import '../utils/app_constants.dart';
import '../utils/storage_util.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // Get authentication headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await StorageUtil.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  // Get user profile
  Future<ApiResponse<Profile>?> getProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('${EnvConfig.apiBaseUrl}${ApiEndpoints.userProfile}'),
            headers: headers,
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final profile = Profile.fromJson(data['data']);
        return ApiResponse<Profile>(
          success: true,
          message: data['message'] ?? 'Profile retrieved successfully',
          data: profile,
        );
      } else if (response.statusCode == 401) {
        debugPrint('Token expired, need to refresh');
        return null;
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<Profile>(
          success: false,
          message: errorData['message'] ?? 'Failed to get profile',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error getting profile: $e');
      return ApiResponse<Profile>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  // Update user profile
  Future<ApiResponse<Profile>?> updateProfile(Profile profile) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'name': profile.name,
        'age': profile.age,
        'gender': profile.gender.toUpperCase(),
        'height': profile.height,
        'weight': profile.weight,
        'activityLevel': _mapActivityLevel(profile.activityLevel),
      });

      final response = await http
          .put(
            Uri.parse('${EnvConfig.apiBaseUrl}${ApiEndpoints.userProfile}'),
            headers: headers,
            body: body,
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final updatedProfile = Profile.fromJson(data['data']);
        return ApiResponse<Profile>(
          success: true,
          message: data['message'] ?? 'Profile updated successfully',
          data: updatedProfile,
        );
      } else if (response.statusCode == 401) {
        debugPrint('Token expired, need to refresh');
        return null;
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<Profile>(
          success: false,
          message: errorData['message'] ?? 'Failed to update profile',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return ApiResponse<Profile>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  // Upload profile image
  Future<ApiResponse<String>?> uploadProfileImage(File imageFile) async {
    try {
      final token = await StorageUtil.getAccessToken();
      final uri =
          Uri.parse('${EnvConfig.apiBaseUrl}${ApiEndpoints.userProfileImage}');

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer ${token ?? ''}';
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));

      final response =
          await request.send().timeout(AppConstants.requestTimeout);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        return ApiResponse<String>(
          success: true,
          message: data['message'] ?? 'Image uploaded successfully',
          data: data['data']['profileImage'],
        );
      } else if (response.statusCode == 401) {
        debugPrint('Token expired, need to refresh');
        return null;
      } else {
        final errorData = json.decode(responseBody);
        return ApiResponse<String>(
          success: false,
          message: errorData['message'] ?? 'Failed to upload image',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return ApiResponse<String>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  // Get dashboard data
  Future<ApiResponse<Map<String, dynamic>>?> getDashboardData(
      {String? date}) async {
    try {
      final headers = await _getHeaders();
      String url = '${EnvConfig.apiBaseUrl}${ApiEndpoints.userDashboard}';
      if (date != null) {
        url += '?date=$date';
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: data['message'] ?? 'Dashboard data retrieved successfully',
          data: data['data'],
        );
      } else if (response.statusCode == 401) {
        debugPrint('Token expired, need to refresh');
        return null;
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: errorData['message'] ?? 'Failed to get dashboard data',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error getting dashboard data: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  // Helper method to map activity level to backend format
  String _mapActivityLevel(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return 'SEDENTARY';
      case 'light':
      case 'lightly':
        return 'LIGHTLY';
      case 'moderate':
      case 'moderately active':
        return 'MODERATELY_ACTIVE';
      case 'very active':
        return 'VERY_ACTIVE';
      case 'extra active':
        return 'EXTRA_ACTIVE';
      default:
        return 'MODERATELY_ACTIVE';
    }
  }
}
