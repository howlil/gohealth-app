import 'dart:convert';
import 'dart:developer';
import 'package:gohealth/core/constants/api_endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/app_constants.dart';
import '../../../configs/env_config.dart';
import '../models/auth_models.dart';

class AuthService {
  late final GoogleSignIn _googleSignIn;
  
  AuthService() {
    _initializeGoogleSignIn();
  }
  
  void _initializeGoogleSignIn() {
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: EnvConfig.googleWebClientId,
    );
  }

  // Google Sign In
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      // Validate client ID is set
      if (EnvConfig.googleWebClientId.contains('NOT_SET')) {
        throw Exception('Google Client ID not configured properly');
      }
      
      // Request Google Sign In
      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) return null;

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleAccount.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get ID token from Google');
      }

      // Send to your backend
      return await _authenticateWithBackend(idToken);
    } catch (e) {
      throw Exception('Google Sign In failed: $e');
    }
  }

  // Authenticate with backend
  Future<AuthResponse> _authenticateWithBackend(String idToken) async {
    final response = await http.post(
      Uri.parse('${EnvConfig.apiBaseUrl}${ApiEndpoints.googleAuth}'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(AuthRequest(idToken: idToken).toJson()),
    ).timeout(AppConstants.requestTimeout);

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(json.decode(response.body));
      await _saveAuthData(authResponse.data);
      return authResponse;
    } else {
      final errorResponse = json.decode(response.body);
      throw Exception(errorResponse['message'] ?? 'Authentication failed');
    }
  }

  // Save authentication data
  Future<void> _saveAuthData(AuthData authData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.accessTokenKey, authData.accessToken);
    await prefs.setString(AppConstants.refreshTokenKey, authData.refreshToken);
    await prefs.setString(AppConstants.userDataKey, json.encode(authData.user.toJson()));
  }

  // Get stored user
  Future<User?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userDataKey);
    if (userJson != null) {
      return User.fromJson(json.decode(userJson));
    }
    return null;
  }

  // Get access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.accessTokenKey);
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.refreshTokenKey);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }

  // Refresh token
  Future<AuthResponse?> refreshToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}${ApiEndpoints.refreshToken}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'refreshToken': refreshToken}),
      ).timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(json.decode(response.body));
        await _saveAuthData(authResponse.data);
        return authResponse;
      }
    } catch (e) {
      // If refresh fails, logout user
      log('Refresh token error: $e');
      await logout();
    }
    return null;
  }

  // Logout
  Future<void> logout() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();
      
      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.accessTokenKey);
      await prefs.remove(AppConstants.refreshTokenKey);
      await prefs.remove(AppConstants.userDataKey);
    } catch (e) {
      log('Logout error: $e');
    }
  }

  // Get current user from API
  Future<User?> getCurrentUser() async {
    final token = await getAccessToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('${EnvConfig.apiBaseUrl}${ApiEndpoints.currentUser}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = User.fromJson(data['data']);
        
        // Update stored user
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.userDataKey, json.encode(user.toJson()));
        
        return user;
      } else if (response.statusCode == 401) {
        // Token might be expired, try to refresh
        final refreshResponse = await refreshToken();
        if (refreshResponse != null) {
          return getCurrentUser(); // Retry with new token
        }
      }
    } catch (e) {
      log('Get current user error: $e');
    }
    return null;
  }
}