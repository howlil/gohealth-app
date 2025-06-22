import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../utils/env_config.dart';
import '../utils/storage_util.dart';
import '../utils/api_endpoints.dart';
import '../models/auth_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final String _baseUrl = EnvConfig.apiBaseUrl;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Login with email and password
  Future<AuthModel?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl${ApiEndpoints.baseUrl}${ApiEndpoints.auth}/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'User-Agent': 'GoHealth-Flutter-App/1.0.0',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final authModel = AuthModel.fromJson(responseData['data']);

          // Save auth data to storage
          await StorageUtil.setAccessToken(authModel.token);
          await StorageUtil.setRefreshToken(authModel.refreshToken);
          await StorageUtil.setUserData({
            'id': authModel.id,
            'name': authModel.name,
            'email': authModel.email,
            'profileImage': authModel.profileImage,
          });
          await StorageUtil.setLoggedIn(true);

          return authModel;
        }
      }

      // Handle error response
      final errorMessage = response.statusCode == 200
          ? 'Login failed: ${response.body}'
          : 'Login failed: ${response.statusCode} ${response.reasonPhrase}';
      debugPrint(errorMessage);
      return null;
    } catch (e) {
      debugPrint('Login error: $e');
      return null;
    }
  }

  // Register new account
  Future<AuthModel?> register(
      String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(
            '$_baseUrl${ApiEndpoints.baseUrl}${ApiEndpoints.auth}/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'User-Agent': 'GoHealth-Flutter-App/1.0.0',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final userData = responseData['data'];

          // After successful registration, automatically login to get tokens
          debugPrint('Registration successful, now logging in...');
          final authModel = await login(email, password);

          if (authModel != null) {
            return authModel;
          } else {
            // If auto-login fails, create AuthModel with empty tokens for now
            // User will need to login manually
            debugPrint(
                'Auto-login after registration failed, creating temporary auth model');

            final tempAuthModel = AuthModel(
              id: userData['id']?.toString() ?? '',
              name: userData['name']?.toString() ?? '',
              email: userData['email']?.toString() ?? '',
              profileImage: userData['profileImage']?.toString(),
              token: '', // Temporary empty token
              refreshToken: '', // Temporary empty token
              age: userData['age'] as int?,
              gender: userData['gender']?.toString(),
              height: userData['height'] != null
                  ? (userData['height'] as num).toDouble()
                  : null,
              weight: userData['weight'] != null
                  ? (userData['weight'] as num).toDouble()
                  : null,
              activityLevel: userData['activityLevel']?.toString(),
              createdAt: userData['createdAt'] != null
                  ? DateTime.tryParse(userData['createdAt'].toString())
                  : null,
              updatedAt: userData['updatedAt'] != null
                  ? DateTime.tryParse(userData['updatedAt'].toString())
                  : null,
            );

            // Save minimal user data to storage
            await StorageUtil.setUserData({
              'id': tempAuthModel.id,
              'name': tempAuthModel.name,
              'email': tempAuthModel.email,
              'profileImage': tempAuthModel.profileImage,
            });
            // Don't set as logged in since we don't have valid tokens
            await StorageUtil.setLoggedIn(false);

            return tempAuthModel;
          }
        }
      }

      // Handle error response
      final errorMessage = response.statusCode == 201
          ? 'Registration failed: ${response.body}'
          : 'Registration failed: ${response.statusCode} ${response.reasonPhrase}';
      debugPrint(errorMessage);
      return null;
    } catch (e) {
      debugPrint('Registration error: $e');
      return null;
    }
  }

  // Logout
  Future<bool> logout() async {
    try {
      final token = await StorageUtil.getAccessToken();

      if (token != null) {
        // Call logout API endpoint if available
        try {
          await http.post(
            Uri.parse(
                '$_baseUrl${ApiEndpoints.baseUrl}${ApiEndpoints.auth}/logout'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
        } catch (e) {
          // Ignore errors from logout API, proceed with local logout
          debugPrint('Logout API error: $e');
        }
      }

      // Clear local auth data
      await StorageUtil.clearAuthData();
      await StorageUtil.setLoggedIn(false);

      return true;
    } catch (e) {
      debugPrint('Logout error: $e');
      return false;
    }
  }

  // Refresh token
  Future<String?> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse(
            '$_baseUrl${ApiEndpoints.baseUrl}${ApiEndpoints.auth}/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final newAccessToken = responseData['data']['accessToken'];
          final newRefreshToken = responseData['data']['refreshToken'];

          // Save new tokens to storage
          await StorageUtil.setAccessToken(newAccessToken);
          if (newRefreshToken != null) {
            await StorageUtil.setRefreshToken(newRefreshToken);
          }

          return newAccessToken;
        }
      }

      debugPrint(
          'Token refresh failed: ${response.statusCode} ${response.reasonPhrase}');
      return null;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      return null;
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await StorageUtil.getAccessToken();
    final isLoggedIn = await StorageUtil.isLoggedIn();

    if (token == null || !isLoggedIn) {
      return false;
    }

    // Check if token is expired
    if (StorageUtil.isTokenExpired(token)) {
      // Try to refresh token
      final refreshToken = await StorageUtil.getRefreshToken();
      if (refreshToken == null) {
        return false;
      }

      final newToken = await this.refreshToken(refreshToken);
      return newToken != null;
    }

    return true;
  }

  // Get current user from storage
  Future<Map<String, dynamic>?> getCurrentUser() async {
    return StorageUtil.getUserData();
  }

  // Reset password request
  Future<bool> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse(
            '$_baseUrl${ApiEndpoints.baseUrl}${ApiEndpoints.auth}/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Password reset request error: $e');
      return false;
    }
  }

  // Reset password with token
  Future<bool> resetPassword(String token, String password) async {
    try {
      final response = await http.post(
        Uri.parse(
            '$_baseUrl${ApiEndpoints.baseUrl}${ApiEndpoints.auth}/reset-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'token': token,
          'password': password,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Password reset error: $e');
      return false;
    }
  }
}
