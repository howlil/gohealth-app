import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gohealth/models/auth_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../models/register_model.dart';
import '../utils/env_config.dart';
import '../utils/api_endpoints.dart';
import '../utils/api_service.dart';
import '../utils/api_response.dart';
import '../utils/storage_util.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final String _baseUrl = EnvConfig.apiBaseUrl;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  late GoogleSignIn _googleSignIn;
  bool _useMockAuth = false; // Development flag

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      debugPrint('Starting Google Sign In...');

      // For development, you can enable mock auth
      if (_useMockAuth) {
        return await mockSignIn();
      }

      // Check if user is already signed in
      GoogleSignInAccount? currentUser = _googleSignIn.currentUser;

      if (currentUser != null) {
        debugPrint('User already signed in: ${currentUser.email}');
        return currentUser;
      }

      // Sign out first to ensure clean state
      await _googleSignIn.signOut();

      // Attempt sign in
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('Google Sign In cancelled by user');
        return null;
      }

      debugPrint('Google Sign In successful: ${googleUser.email}');

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      debugPrint(
          'Access Token: ${googleAuth.accessToken != null ? 'Available' : 'Missing'}');
      debugPrint(
          'ID Token: ${googleAuth.idToken != null ? 'Available' : 'Missing'}');

      return googleUser;
    } catch (error) {
      final errorString = error.toString();
      debugPrint('Google Sign In failed - check configuration');
      debugPrint('Error details: $error');

      if (errorString.contains('sign_in_failed') &&
          errorString.contains('10')) {
        debugPrint('Configuration Error - API Exception 10');
        debugPrint('This usually means:');
        debugPrint('1. SHA-1 fingerprint not registered in Firebase Console');
        debugPrint('2. google-services.json file is invalid or missing');
        debugPrint('3. Package name mismatch');
        debugPrint('4. Google Sign-In not enabled in Firebase Auth');

        throw Exception('Google Sign-In configuration error. Please check:\n'
            '1. SHA-1 fingerprint in Firebase Console\n'
            '2. google-services.json file\n'
            '3. Package name configuration');
      }

      if (errorString.contains('popup_closed')) {
        debugPrint('Google Sign In popup closed by user');
        return null;
      }

      rethrow;
    }
  }

  // Mock sign in for development
  Future<GoogleSignInAccount?> mockSignIn() async {
    debugPrint('Using mock Google Sign In');
    // Initialize GoogleSignIn if not already initialized
    if (_googleSignIn == null) {
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
    }

    // For mock sign in, we'll just return null to simulate a cancelled sign in
    // This is safer than trying to create mock instances of GoogleSignInAccount
    return null;
  }

  // Enable mock authentication for development
  void enableMockAuth() {
    _useMockAuth = true;
    debugPrint('Mock authentication enabled for development');
  }

  // Disable mock authentication
  void disableMockAuth() {
    _useMockAuth = false;
    debugPrint('Mock authentication disabled - using real Google Sign In');
  }

  // Get SHA-1 fingerprint for debugging
  Future<void> printDebugInfo() async {
    try {
      debugPrint('=== Google Sign-In Debug Info ===');
      debugPrint('Current user: ${_googleSignIn.currentUser?.email ?? 'None'}');
      debugPrint(
          'Client ID configured: ${_googleSignIn.clientId ?? 'Default'}');
      debugPrint('Scopes: ${_googleSignIn.scopes}');

      // Test sign in silently
      final silentUser = await _googleSignIn.signInSilently();
      debugPrint('Silent sign in result: ${silentUser?.email ?? 'Failed'}');
    } catch (e) {
      debugPrint('Debug info error: $e');
    }
  }

  // Authenticate with backend (if you have one)
  Future<AuthResponse?> authenticateWithBackend(String idToken) async {
    try {
      // Replace with your actual backend URL
      final response = await http
          .post(
            Uri.parse('YOUR_BACKEND_URL/auth/google'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({'idToken': idToken}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(json.decode(response.body));
        await _saveAuthData(authResponse.data);
        return authResponse;
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['message'] ?? 'Authentication failed');
      }
    } catch (e) {
      debugPrint('Backend authentication error: $e');
      return null;
    }
  }

  // Save authentication data
  Future<void> _saveAuthData(AuthResponseData authData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', authData.accessToken);
      await prefs.setString('refresh_token', authData.refreshToken);
      await prefs.setString('user_data', json.encode(authData.user.toJson()));
    } catch (e) {
      debugPrint('Error saving auth data: $e');
    }
  }

  Future<AuthModel?> getStoredUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');
      if (userJson != null) {
        return AuthModel.fromJson(json.decode(userJson));
      }
    } catch (e) {
      debugPrint('Error getting stored user: $e');
    }
    return null;
  }

  // Get access token
  Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('access_token');
    } catch (e) {
      debugPrint('Error getting access token: $e');
      return null;
    }
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('refresh_token');
    } catch (e) {
      debugPrint('Error getting refresh token: $e');
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      // Check both Google Sign-In state and stored token
      final currentUser = _googleSignIn.currentUser;
      final token = await getAccessToken();

      return currentUser != null || token != null;
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return false;
    }
  }

  // Refresh token
  Future<AuthResponse?> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return null;

      final response = await http
          .post(
            Uri.parse('YOUR_BACKEND_URL/auth/refresh'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(json.decode(response.body));
        await _saveAuthData(authResponse.data);
        return authResponse;
      }
    } catch (e) {
      debugPrint('Refresh token error: $e');
      await logout();
    }
    return null;
  }

  // Logout
  Future<void> logout() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_data');

      debugPrint('Logout successful');
    } catch (e) {
      debugPrint('Logout error: $e');
      rethrow;
    }
  }

  // Get current user from API
  Future<AuthModel?> getCurrentUser() async {
    try {
      final token = await getAccessToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('YOUR_BACKEND_URL/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = AuthModel.fromJson(data['data']);

        // Update stored user
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', json.encode(user.toJson()));

        return user;
      } else if (response.statusCode == 401) {
        // Token might be expired, try to refresh
        final refreshResponse = await refreshToken();
        if (refreshResponse != null) {
          return getCurrentUser(); // Retry with new token
        }
      }
    } catch (e) {
      debugPrint('Get current user error: $e');
    }
    return null;
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      debugPrint('Google Sign Out successful');
    } catch (error) {
      debugPrint('Sign out error: $error');
      rethrow;
    }
  }

  // Login with email and password
  Future<ApiResponse<AuthModel>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl${ApiEndpoints.baseUrl}${ApiEndpoints.auth}/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['data'] == null) {
          return ApiResponse.error('Invalid response format');
        }

        // Store tokens
        await StorageUtil.setAccessToken(data['data']['accessToken']);
        await StorageUtil.setRefreshToken(data['data']['refreshToken']);

        return ApiResponse.success(
          AuthModel.fromJson(data['data']),
          message: data['message'] ?? 'Login successful',
        );
      } else {
        final errorMessage = data['message'] ?? 'Invalid credentials';
        return ApiResponse.error(errorMessage);
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<AuthModel>?> register(RegisterModel registerData) async {
    try {
      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/api${ApiEndpoints.auth}/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(registerData.toJson()),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 201) {
        return ApiResponse<AuthModel>(
          success: true,
          message: data['message'] ?? 'Registration successful',
          data: AuthModel.fromJson(data['data']),
        );
      } else {
        return ApiResponse<AuthModel>(
          success: false,
          message: data['message'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      return ApiResponse<AuthModel>(
        success: false,
        message: e.toString(),
      );
    }
  }
}

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse<T>(
      success: true,
      message: message ?? 'Operation successful',
      data: data,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse<T>(
      success: false,
      message: message,
      data: null,
    );
  }
}
