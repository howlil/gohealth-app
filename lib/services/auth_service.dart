import 'dart:async';
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
    // Coba beberapa kemungkinan endpoint dengan timeout
    final List<String> possibleEndpoints = [
      '/auth/login', // Tanpa /api prefix
      '/api/auth/login', // Dengan /api prefix
      '/login', // Langsung ke /login
    ];

    String lastError = '';

    // Try endpoints one by one (not concurrently) to reduce memory load
    for (String endpoint in possibleEndpoints) {
      try {
        final loginUrl = '$_baseUrl$endpoint';
        debugPrint('🔗 AuthService trying login URL: $loginUrl');
        debugPrint('📤 AuthService login data: email=$email');

        final response = await http
            .post(
          Uri.parse(loginUrl),
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
        )
            .timeout(
          const Duration(seconds: 10), // Reduced timeout
          onTimeout: () {
            throw TimeoutException('Request timeout for endpoint: $endpoint');
          },
        );

        debugPrint(
            '📊 AuthService login response status: ${response.statusCode}');
        debugPrint(
            '📥 AuthService login response body: ${response.body.length > 200 ? response.body.substring(0, 200) + "..." : response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
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

            debugPrint(
                '✅ AuthService: Login successful with endpoint: $endpoint');
            return authModel;
          } else {
            debugPrint(
                '❌ AuthService: Login response missing data or success flag');
            debugPrint('   Response structure: ${responseData.keys.toList()}');
          }
        } else if (response.statusCode == 404) {
          // 404 berarti endpoint tidak ditemukan, coba endpoint berikutnya
          debugPrint(
              '⚠️ AuthService: Endpoint $endpoint not found (404), trying next...');
          lastError = 'Endpoint $endpoint not found';

          // Add small delay before trying next endpoint to prevent overwhelming server
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        } else {
          // Error lain selain 404, tidak perlu coba endpoint lain
          lastError =
              'AuthService Login failed (${response.statusCode}): ${response.body}';
          debugPrint('❌ $lastError');
          break;
        }
      } on TimeoutException catch (e) {
        debugPrint('⏰ AuthService login timeout with endpoint $endpoint: $e');
        lastError = 'Timeout: $e';
        continue;
      } catch (e) {
        debugPrint('❌ AuthService login error with endpoint $endpoint: $e');
        lastError = 'Network error: $e';

        // Add delay before trying next endpoint
        await Future.delayed(const Duration(milliseconds: 500));
        continue;
      }
    }

    // Jika semua endpoint gagal
    debugPrint(
        '❌ AuthService: All login endpoints failed. Last error: $lastError');
    return null;
  }

  // Register new account
  Future<AuthModel?> register(
      String name, String email, String password) async {
    // Coba beberapa kemungkinan endpoint dengan timeout
    final List<String> possibleEndpoints = [
      '/auth/register', // Tanpa /api prefix
      '/api/auth/register', // Dengan /api prefix
      '/register', // Langsung ke /register
    ];

    String lastError = '';

    // Try endpoints one by one (not concurrently) to reduce memory load
    for (String endpoint in possibleEndpoints) {
      try {
        final registerUrl = '$_baseUrl$endpoint';
        debugPrint('🔗 AuthService trying register URL: $registerUrl');
        debugPrint('📤 AuthService register data: name=$name, email=$email');

        final response = await http
            .post(
          Uri.parse(registerUrl),
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
        )
            .timeout(
          const Duration(seconds: 10), // Reduced timeout
          onTimeout: () {
            throw TimeoutException('Request timeout for endpoint: $endpoint');
          },
        );

        debugPrint(
            '📊 AuthService register response status: ${response.statusCode}');
        debugPrint(
            '📥 AuthService register response body: ${response.body.length > 200 ? response.body.substring(0, 200) + "..." : response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body);

          if (responseData['success'] == true && responseData['data'] != null) {
            final userData = responseData['data'];

            debugPrint(
                '✅ AuthService: Registration successful with endpoint: $endpoint');

            // Jangan auto-login setelah register, biarkan user tetap di halaman register
            debugPrint(
                '✅ AuthService: Registration successful, creating temp auth model');

            final tempAuthModel = AuthModel(
              id: userData['id']?.toString() ?? '',
              name: userData['name']?.toString() ?? '',
              email: userData['email']?.toString() ?? '',
              profileImage: userData['profileImage']?.toString(),
              token: '', // Kosongkan token agar tidak auto-login
              refreshToken: '', // Kosongkan refresh token
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

            // Jangan save ke storage sebagai logged in user
            await StorageUtil.setUserData({
              'id': tempAuthModel.id,
              'name': tempAuthModel.name,
              'email': tempAuthModel.email,
              'profileImage': tempAuthModel.profileImage,
            });
            await StorageUtil.setLoggedIn(
                false); // Penting: set false agar tidak auto-login

            return tempAuthModel;
          } else {
            debugPrint(
                '❌ AuthService: Registration response missing data or success flag');
            debugPrint('   Response structure: ${responseData.keys.toList()}');
          }
        } else if (response.statusCode == 404) {
          // 404 berarti endpoint tidak ditemukan, coba endpoint berikutnya
          debugPrint(
              '⚠️ AuthService: Endpoint $endpoint not found (404), trying next...');
          lastError = 'Endpoint $endpoint not found';

          // Add small delay before trying next endpoint
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        } else {
          // Error lain selain 404, tidak perlu coba endpoint lain
          lastError =
              'AuthService Registration failed (${response.statusCode}): ${response.body}';
          debugPrint('❌ $lastError');
          break;
        }
      } on TimeoutException catch (e) {
        debugPrint(
            '⏰ AuthService registration timeout with endpoint $endpoint: $e');
        lastError = 'Timeout: $e';
        continue;
      } catch (e) {
        debugPrint(
            '❌ AuthService registration error with endpoint $endpoint: $e');
        lastError = 'Network error: $e';

        // Add delay before trying next endpoint
        await Future.delayed(const Duration(milliseconds: 500));
        continue;
      }
    }

    // Jika semua endpoint gagal
    debugPrint(
        '❌ AuthService: All registration endpoints failed. Last error: $lastError');
    return null;
  }

  // Logout
  Future<bool> logout() async {
    try {
      final token = await StorageUtil.getAccessToken();

      if (token != null) {
        // Call logout API endpoint if available
        try {
          final logoutUrl = '$_baseUrl${ApiEndpoints.logout}';
          debugPrint('🔗 AuthService logout URL: $logoutUrl');

          await http.post(
            Uri.parse(logoutUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
          debugPrint('✅ AuthService: Logout API called');
        } catch (e) {
          // Ignore errors from logout API, proceed with local logout
          debugPrint('⚠️ AuthService logout API error: $e');
        }
      }

      // Clear local auth data
      await StorageUtil.clearAuthData();
      await StorageUtil.setLoggedIn(false);

      debugPrint('✅ AuthService: Local logout completed');
      return true;
    } catch (e) {
      debugPrint('❌ AuthService logout error: $e');
      return false;
    }
  }

  // Refresh token
  Future<String?> refreshToken(String refreshToken) async {
    try {
      final refreshUrl = '$_baseUrl${ApiEndpoints.refreshToken}';
      debugPrint('🔗 AuthService refresh token URL: $refreshUrl');

      final response = await http.post(
        Uri.parse(refreshUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      debugPrint(
          '📊 AuthService refresh token response status: ${response.statusCode}');
      debugPrint(
          '📥 AuthService refresh token response body: ${response.body}');

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

          debugPrint('✅ AuthService: Token refreshed successfully');
          return newAccessToken;
        }
      }

      debugPrint(
          '❌ AuthService token refresh failed: ${response.statusCode} ${response.reasonPhrase}');
      return null;
    } catch (e) {
      debugPrint('❌ AuthService token refresh error: $e');
      return null;
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await StorageUtil.getAccessToken();
    final isLoggedIn = await StorageUtil.isLoggedIn();

    debugPrint(
        '🔍 AuthService checking authentication: token=${token != null ? 'exists' : 'null'}, isLoggedIn=$isLoggedIn');

    if (token == null || !isLoggedIn) {
      debugPrint(
          '❌ AuthService: Not authenticated - missing token or not logged in');
      return false;
    }

    // Check if token is expired
    if (StorageUtil.isTokenExpired(token)) {
      debugPrint('⚠️ AuthService: Token expired, attempting refresh...');
      // Try to refresh token
      final refreshToken = await StorageUtil.getRefreshToken();
      if (refreshToken == null) {
        debugPrint('❌ AuthService: No refresh token available');
        return false;
      }

      final newToken = await this.refreshToken(refreshToken);
      final isRefreshed = newToken != null;
      debugPrint('🔄 AuthService: Token refresh result: $isRefreshed');
      return isRefreshed;
    }

    debugPrint('✅ AuthService: User is authenticated');
    return true;
  }

  // Get current user from storage
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final userData = await StorageUtil.getUserData();
    debugPrint(
        '👤 AuthService getCurrentUser: ${userData != null ? 'found' : 'null'}');
    return userData;
  }

  // Reset password request
  Future<bool> requestPasswordReset(String email) async {
    try {
      final forgotPasswordUrl = '$_baseUrl${ApiEndpoints.forgotPassword}';
      debugPrint('🔗 AuthService forgot password URL: $forgotPasswordUrl');

      final response = await http.post(
        Uri.parse(forgotPasswordUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      debugPrint(
          '📊 AuthService forgot password response status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ AuthService password reset request error: $e');
      return false;
    }
  }

  // Reset password with token
  Future<bool> resetPassword(String token, String password) async {
    try {
      final resetPasswordUrl = '$_baseUrl${ApiEndpoints.resetPassword}';
      debugPrint('🔗 AuthService reset password URL: $resetPasswordUrl');

      final response = await http.post(
        Uri.parse(resetPasswordUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'token': token,
          'password': password,
        }),
      );

      debugPrint(
          '📊 AuthService reset password response status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ AuthService password reset error: $e');
      return false;
    }
  }
}
