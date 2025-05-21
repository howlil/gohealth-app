import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/app_constants.dart';
import '../models/auth_models.dart';

class AuthService {
  late final GoogleSignIn _googleSignIn;
  final ValueNotifier<bool> webSignInButtonVisible = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSigningIn = ValueNotifier<bool>(false);

  // Completer for web sign-in flow
  Completer<GoogleSignInAccount?>? _webSignInCompleter;
  
  // Stream controller for auth state changes
  final _authStateController = StreamController<User?>.broadcast();
  
  // Cached values to reduce SharedPreferences access
  User? _cachedUser;
  String? _cachedToken;
  bool _initialized = false;

  // Your Google Client IDs (consider moving these to an env config)
  static const String _webClientId =
      '845113946067-e1q5mruppe349adma00c4gi9tvf2uqrl.apps.googleusercontent.com';
  static const String _androidClientId =
      '845113946067-hvg4pfb2ncjicg8mh8en5ouckugkdbeh.apps.googleusercontent.com';
  static const String _iosClientId =
      '845113946067-hvg4pfb2ncjicg8mh8en5ouckugkdbeh.apps.googleusercontent.com';
      
  // API base URL (move to env config)
  static const String _apiBaseUrl = 'https://piglet-amused-willingly.ngrok-free.app/api/v1';

  AuthService() {
    _initializeGoogleSignIn();
    _loadCachedUserData();
  }

  // Initialize the Google Sign-In configuration
  void _initializeGoogleSignIn() {
    if (_initialized) return;
    
    if (kIsWeb) {
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile', 'openid'],
        clientId: _webClientId,
      );
      
      // Initialize the web sign-in handler
      _googleSignIn.onCurrentUserChanged.listen(_handleWebUserChanged);
      _trySilentSignIn();
    } else {
      // Platform-specific initialization
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile', 'openid'],
        clientId: kIsWeb ? null : (Platform.isIOS ? _iosClientId : _androidClientId),
        serverClientId: _webClientId,
      );
    }
    
    _initialized = true;
  }

  // Load cached user data to avoid excessive shared preferences access
  Future<void> _loadCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.userDataKey);
      final token = prefs.getString(AppConstants.accessTokenKey);
      
      if (userJson != null) {
        _cachedUser = User.fromJson(json.decode(userJson));
        _authStateController.add(_cachedUser);
      }
      
      _cachedToken = token;
    } catch (e) {
      debugPrint('Failed to load cached user data: $e');
    }
  }

  // Web user change handler
  void _handleWebUserChanged(GoogleSignInAccount? account) async {
    if (account == null) return;
    
    isSigningIn.value = true;
    try {
      final response = await _processGoogleSignIn(account);
      if (_webSignInCompleter != null && !_webSignInCompleter!.isCompleted) {
        _webSignInCompleter!.complete(account);
      }
    } catch (e) {
      if (_webSignInCompleter != null && !_webSignInCompleter!.isCompleted) {
        _webSignInCompleter!.completeError(e);
      }
    } finally {
      isSigningIn.value = false;
    }
  }

  // Try silent sign-in (offloaded from main thread)
  Future<void> _trySilentSignIn() async {
    try {
      await _googleSignIn.signInSilently();
    } catch (e) {
      // Silent failure is expected
    }
  }

  // Main sign-in method
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      isSigningIn.value = true;
      
      // For web platform, use web-specific method
      if (kIsWeb) {
        return await _signInWithGoogleWeb();
      }
      
      // For mobile platforms, use standard approach
      await _googleSignIn.signOut(); // Clear previous sessions
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null; // User canceled
      }
      
      return await _processGoogleSignIn(googleUser);
    } catch (e) {
      if (e is PlatformException) {
        debugPrint('Platform error: ${e.code} - ${e.message}');
      } else {
        debugPrint('Sign-in error: $e');
      }
      rethrow;
    } finally {
      isSigningIn.value = false;
    }
  }

  // Web-specific sign-in
  Future<AuthResponse?> _signInWithGoogleWeb() async {
    try {
      // Clean up previous sessions
      await _googleSignIn.signOut();
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Create completer for the async flow
      _webSignInCompleter = Completer<GoogleSignInAccount?>();
      webSignInButtonVisible.value = true;
      
      final GoogleSignInAccount? googleUser = await _webSignInCompleter!.future;
      
      webSignInButtonVisible.value = false;
      
      if (googleUser == null) {
        return null; // User canceled
      }
      
      return await _processGoogleSignIn(googleUser);
    } catch (e) {
      debugPrint('Web sign-in error: $e');
      rethrow;
    } finally {
      webSignInButtonVisible.value = false;
    }
  }

  // Process Google Sign-In
  Future<AuthResponse?> _processGoogleSignIn(GoogleSignInAccount googleUser) async {
    try {
      // Get authentication data
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final String? idToken = googleAuth.idToken;
      
      if (idToken == null) {
        throw Exception('No ID token received from Google');
      }
      
      // Authenticate with backend
      return await _authenticateWithBackend(idToken);
    } catch (e) {
      debugPrint('Process sign-in error: $e');
      rethrow;
    }
  }

  // Backend authentication
  Future<AuthResponse> _authenticateWithBackend(String idToken) async {
    try {
      final url = '$_apiBaseUrl/auth/google';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"idToken": idToken}),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(json.decode(response.body));
        await _saveAuthData(authResponse.data);
        return authResponse;
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Authentication failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Backend authentication error: $e');
      rethrow;
    }
  }

  // Handle sign-in button click
  Future<void> handleGoogleSignInButtonClick() async {
    if (!kIsWeb) return;
    
    try {
      isSigningIn.value = true;
      
      // Clear previous sessions
      await _googleSignIn.signOut();
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Trigger sign-in
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      
      if (account == null && _webSignInCompleter != null && !_webSignInCompleter!.isCompleted) {
        _webSignInCompleter!.complete(null);
      }
    } catch (e) {
      if (_webSignInCompleter != null && !_webSignInCompleter!.isCompleted) {
        _webSignInCompleter!.completeError(e);
      }
    } finally {
      isSigningIn.value = false;
    }
  }

  // Save authentication data
  Future<void> _saveAuthData(AuthData authData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.accessTokenKey, authData.accessToken);
      await prefs.setString(AppConstants.refreshTokenKey, authData.refreshToken);
      await prefs.setString(AppConstants.userDataKey, json.encode(authData.user.toJson()));
      
      // Update cached values
      _cachedUser = authData.user;
      _cachedToken = authData.accessToken;
      
      // Notify listeners
      _authStateController.add(_cachedUser);
    } catch (e) {
      debugPrint('Error saving auth data: $e');
      throw Exception('Failed to save authentication data');
    }
  }

  // Get stored user
  Future<User?> getStoredUser() async {
    if (_cachedUser != null) return _cachedUser;
    
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userDataKey);
    
    if (userJson != null) {
      _cachedUser = User.fromJson(json.decode(userJson));
      return _cachedUser;
    }
    
    return null;
  }

  // Get access token
  Future<String?> getAccessToken() async {
    if (_cachedToken != null) return _cachedToken;
    
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(AppConstants.accessTokenKey);
    return _cachedToken;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }

  // Refresh token
  Future<AuthResponse?> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(AppConstants.refreshTokenKey);
    
    if (refreshToken == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': refreshToken}),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(json.decode(response.body));
        await _saveAuthData(authResponse.data);
        return authResponse;
      }
    } catch (e) {
      debugPrint('Refresh token error: $e');
      await signOut(); // Logout on refresh failure
    }
    
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Perform asynchronous operations in parallel
      await Future.wait([
        _googleSignIn.signOut(),
        _clearLocalStorage(),
      ]);
      
      // Clear cached values
      _cachedUser = null;
      _cachedToken = null;
      
      // Notify listeners
      _authStateController.add(null);
    } catch (e) {
      debugPrint('Sign-out error: $e');
    }
  }

  // Alias for signOut
  Future<void> logout() => signOut();

  // Clear local storage
  Future<void> _clearLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userDataKey);
  }

  // Get current user from API
  Future<User?> getCurrentUser() async {
    final token = await getAccessToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = User.fromJson(data['data']);
        
        // Update stored user
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.userDataKey, json.encode(user.toJson()));
        
        // Update cached user
        _cachedUser = user;
        
        // Notify listeners
        _authStateController.add(_cachedUser);
        
        return user;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
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

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _authStateController.stream;

  // Dispose resources
  void dispose() {
    _authStateController.close();
    webSignInButtonVisible.dispose();
    isSigningIn.dispose();
  }
}