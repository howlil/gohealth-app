import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'dart:convert';
import '../models/user_profile_model.dart';
import '../utils/env_config.dart';
import '../utils/api_endpoints.dart';
import '../utils/api_response.dart';
import '../utils/storage_util.dart';
import '../utils/api_service.dart';
import 'package:flutter/material.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  final String _baseUrl = EnvConfig.apiBaseUrl;
  final ApiService _apiService = ApiService();

  factory UserService() {
    return _instance;
  }

  UserService._internal();

  Future<UserProfileResponse?> getCurrentUser() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.users + '/profile',
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return UserProfileResponse(
          success: true,
          message: response['message'] ?? 'Success',
          data: UserProfileData.fromJson(response['data']),
        );
      } else {
        return UserProfileResponse(
          success: false,
          message: response['message'] ?? 'Failed to get user profile',
          data: UserProfileData(
            id: '',
            name: '',
            email: '',
          ),
        );
      }
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return UserProfileResponse(
        success: false,
        message: e.toString(),
        data: UserProfileData(
          id: '',
          name: '',
          email: '',
        ),
      );
    }
  }

  Future<UserProfileResponse?> updateProfile(UserProfileData profile) async {
    try {
      // Convert model to API request format - only include non-null fields
      final Map<String, dynamic> requestBody = {};

      // Always include name as it's likely required
      if (profile.name.isNotEmpty) {
        requestBody['name'] = profile.name;
      }

      // Only include optional fields if they have valid values
      if (profile.age != null && profile.age! > 0) {
        requestBody['age'] = profile.age;
      }

      if (profile.gender != null && profile.gender!.isNotEmpty) {
        requestBody['gender'] = profile.gender;
      }

      if (profile.height != null && profile.height! > 0) {
        requestBody['height'] = profile.height;
      }

      if (profile.weight != null && profile.weight! > 0) {
        requestBody['weight'] = profile.weight;
      }

      if (profile.activityLevel != null && profile.activityLevel!.isNotEmpty) {
        requestBody['activityLevel'] = profile.activityLevel;
      }

      debugPrint('UpdateProfile request body: $requestBody');

      final response = await _apiService.put(
        ApiEndpoints.users + '/profile',
        body: requestBody,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return UserProfileResponse(
          success: true,
          message: response['message'] ?? 'Profile updated successfully',
          data: UserProfileData.fromJson(response['data']),
        );
      } else {
        debugPrint('UpdateProfile failed: ${response['message']}');
        return UserProfileResponse(
          success: false,
          message: response['message'] ?? 'Failed to update profile',
          data: profile,
        );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return UserProfileResponse(
        success: false,
        message: e.toString(),
        data: profile,
      );
    }
  }

  Future<ApiResponse<String>?> uploadProfileImage(File image) async {
    try {
      final token = await StorageUtil.getAccessToken();

      if (token == null) {
        return ApiResponse.error('Authentication token not found');
      }

      // Validate file extension
      final fileName = image.path.split('/').last.toLowerCase();
      final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      final fileExtension = fileName.split('.').last;

      if (!validExtensions.contains(fileExtension)) {
        return ApiResponse.error(
            'File harus berformat gambar (JPG, JPEG, PNG, GIF, WEBP)');
      }

      // Determine MIME type
      String contentType;
      switch (fileExtension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg'; // Default fallback
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl${ApiEndpoints.users}/profile/image'),
      );

      // Add authorization header
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Add file to the request with explicit content type
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        image.path,
        contentType: http_parser.MediaType.parse(contentType),
      );

      request.files.add(multipartFile);

      debugPrint('Uploading image: $fileName');
      debugPrint('Content-Type: $contentType');

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Upload response status: ${response.statusCode}');
      debugPrint('Upload response body: ${response.body}');

      // Parse response
      final responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        // Get the image URL from response
        final imageUrl = responseData['data']['profileImage'];

        return ApiResponse.success(
          imageUrl,
          message: responseData['message'] ?? 'Image uploaded successfully',
        );
      } else {
        return ApiResponse.error(
          responseData['message'] ?? 'Failed to upload image',
        );
      }
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<Map<String, dynamic>>?> getDashboardData({
    String? date,
    String range = 'week',
    String? month,
  }) async {
    try {
      // Build query parameters
      final Map<String, String> queryParams = {
        if (date != null) 'date': date,
        'range': range,
        if (month != null) 'month': month,
      };

      final response = await _apiService.get(
        ApiEndpoints.dashboard,
        requiresAuth: true,
        queryParams: queryParams,
      );

      if (response['success'] == true) {
        return ApiResponse.success(
          response['data'],
          message:
              response['message'] ?? 'Dashboard data retrieved successfully',
        );
      } else {
        return ApiResponse.error(
          response['message'] ?? 'Failed to get dashboard data',
        );
      }
    } catch (e) {
      debugPrint('Error getting dashboard data: $e');
      return ApiResponse.error(e.toString());
    }
  }
}
