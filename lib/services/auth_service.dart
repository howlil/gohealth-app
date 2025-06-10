import 'dart:convert';
import 'dart:developer';
import 'package:gohealth/api/end_point.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gohealth/models/auth_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class AuthService {
  late GoogleSignIn _googleSignIn;

  AuthService() {
    _initializeGoogleSignIn();
  }

  void _initializeGoogleSignIn() {
    if (kIsWeb) {
      _googleSignIn = GoogleSignIn(
        clientId: EnvConfig.googleWebClientId,
        scopes: ['email', 'profile'],
      );
    } else {
      _googleSignIn = GoogleSignIn(
        serverClientId: EnvConfig.googleWebClientId,
        scopes: ['email', 'profile'],
      );
    }
  }

  // Google Sign In
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google Sign In cancelled by user');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      return googleUser;
    } catch (error) {
      log('Google sign in error: $error');
      rethrow;
    }
  }
  // Authenticate with backend
  Future<AuthResponse> _authenticateWithBackend(String idToken) async {
    final response = await http
        .post(
          Uri.parse('${EnvConfig.apiBaseUrl}${ApiEndpoints.googleAuth}'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode(AuthRequest(idToken: idToken).toJson()),
        )
        .timeout(AppConstants.requestTimeout);

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
  Future<void> _saveAuthData(AuthResponseData authData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.accessTokenKey, authData.accessToken);
    await prefs.setString(AppConstants.refreshTokenKey, authData.refreshToken);
    await prefs.setString(
        AppConstants.userDataKey, json.encode(authData.user.toJson()));
  }

  Future<AuthModel?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userDataKey);
    if (userJson != null) {
      return AuthModel.fromJson(json.decode(userJson));
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
      final response = await http
          .post(
            Uri.parse('${EnvConfig.apiBaseUrl}${ApiEndpoints.refreshToken}'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({'refreshToken': refreshToken}),
          )
          .timeout(AppConstants.requestTimeout);

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
      await _googleSignIn.signOut();

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.accessTokenKey);
      await prefs.remove(AppConstants.refreshTokenKey);
      await prefs.remove(AppConstants.userDataKey);
    } catch (e) {
      log('Logout error: $e');
      rethrow;
    }
  }

  // Get current user from API
  Future<AuthModel?> getCurrentUser() async {
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
        final user = AuthModel.fromJson(data['data']);

        // Update stored user
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            AppConstants.userDataKey, json.encode(user.toJson()));

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

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (error) {
      debugPrint('Sign out error: $error');
      rethrow;
    }
  }
}
