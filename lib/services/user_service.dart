import 'dart:io';
import 'package:http/http.dart' as http;
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

  Future<ApiResponse<UserProfileData>> getCurrentUser() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.me,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return ApiResponse.success(
          UserProfileData.fromJson(response['data']),
          message: response['message'] ?? 'Success',
        );
      } else {
        return ApiResponse.error(
          response['message'] ?? 'Failed to get user profile',
          statusCode: response['statusCode'],
        );
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<UserProfileData>> updateProfile(
      UserProfileData profile) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.updateProfile,
        body: profile.toJson(),
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return ApiResponse.success(
          UserProfileData.fromJson(response['data']),
          message: response['message'] ?? 'Profile updated successfully',
        );
      } else {
        return ApiResponse.error(
          response['message'] ?? 'Failed to update profile',
          statusCode: response['statusCode'],
        );
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<String>> uploadProfileImage(File image) async {
    try {
      final headers = await _apiService.getHeaders();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl${ApiEndpoints.uploadProfileImage}'),
      );

      request.headers.addAll(headers);
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
      final response = await _apiService.get(
        ApiEndpoints.dashboard,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return ApiResponse.success(
          response['data'],
          message: response['message'] ?? 'Success',
        );
      } else {
        return ApiResponse.error(
          response['message'] ?? 'Failed to get dashboard data',
          statusCode: response['statusCode'],
        );
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}
