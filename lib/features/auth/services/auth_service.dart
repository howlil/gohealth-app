import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
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
    // Fix: Simplified configuration, removed serverClientId that might cause issues
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
    );
  }

  // Google Sign In
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      // Add proper logging for debugging
      log('Starting Google Sign In process');
      
      // Fix: Handle sign-in silently first to check existing accounts
      GoogleSignInAccount? googleAccount;
      try {
        googleAccount = await _googleSignIn.signInSilently();
      } catch (e) {
        log('Silent sign-in failed: $e');
        // Silent sign-in failed, continue with interactive sign-in
      }
      
      // If silent sign-in failed, try interactive sign-in
      if (googleAccount == null) {
        try {
          googleAccount = await _googleSignIn.signIn();
        } catch (e) {
          log('Interactive sign-in failed: $e');
          throw Exception('Failed to sign in with Google: $e');
        }
      }
      
      // User cancelled the sign-in
      if (googleAccount == null) {
        log('User cancelled sign-in');
        return null;
      }

      // Get authentication details
      log('Getting auth details for account: ${googleAccount.email}');
      final GoogleSignInAuthentication googleAuth = await googleAccount.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get ID token from Google');
      }

      log('Successfully obtained ID token, authenticating with backend');
      
      // For debugging: demonstrate token is available
      log('Token length: ${idToken.length}');
      
      // Fix: For testing, if backend is not available, create a mock response
      // This allows testing the flow even if the backend is not available
      if (EnvConfig.apiBaseUrl.contains('NOT_CONFIGURED')) {
        log('Using mock auth response as API URL is not configured');
        return _createMockAuthResponse(googleAccount);
      }

      // Send to your backend
      return await _authenticateWithBackend(idToken);
    } catch (e) {
      log('Google Sign In error: $e');
      // Properly rethrow for better tracing
      rethrow;
    }
  }

  // Authentication with backend
  Future<AuthResponse> _authenticateWithBackend(String idToken) async {
    try {
      log('Sending auth request to: ${EnvConfig.apiBaseUrl}/auth/google');
      
      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/auth/google'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({"idToken": idToken}),
      ).timeout(AppConstants.requestTimeout);

      log('Auth response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(json.decode(response.body));
        await _saveAuthData(authResponse.data);
        return authResponse;
      } else {
        final errorBody = response.body;
        log('Auth error response: $errorBody');
        
        try {
          final errorResponse = json.decode(errorBody);
          throw Exception(errorResponse['message'] ?? 'Authentication failed');
        } catch (e) {
          throw Exception('Authentication failed with status ${response.statusCode}');
        }
      }
    } catch (e) {
      log('Backend authentication error: $e');
      rethrow;
    }
  }

  // Mock auth response for testing
  AuthResponse _createMockAuthResponse(GoogleSignInAccount account) {
    final user = User(
      id: 'mock-user-id-${DateTime.now().millisecondsSinceEpoch}',
      email: account.email,
      name: account.displayName ?? 'User',
      profileImage: account.photoUrl,
    );
    
    final authData = AuthData(
      user: user,
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
      tokenType: 'Bearer',
      expiresIn: '3600',
    );
    
    _saveAuthData(authData);
    
    return AuthResponse(
      success: true,
      statusCode: 200,
      message: 'Authenticated successfully',
      data: authData,
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  // Save authentication data
  Future<void> _saveAuthData(AuthData authData) async {
    try {
      log('Saving auth data');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.accessTokenKey, authData.accessToken);
      await prefs.setString(AppConstants.refreshTokenKey, authData.refreshToken);
      await prefs.setString(AppConstants.userDataKey, json.encode(authData.user.toJson()));
      log('Auth data saved successfully');
    } catch (e) {
      log('Error saving auth data: $e');
      throw Exception('Failed to save authentication data: $e');
    }
  }

  // Remaining methods unchanged...
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
        Uri.parse('${EnvConfig.apiBaseUrl}/auth/refresh'),
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
        Uri.parse('${EnvConfig.apiBaseUrl}/auth/me'),
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