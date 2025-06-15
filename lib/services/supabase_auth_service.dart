import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gohealth/models/auth_model.dart' hide AuthState, AuthResponse;
import '../models/login_model.dart';
import '../utils/api_response.dart';
import '../utils/http_exception.dart';
import '../utils/storage_util.dart';

class SupabaseAuthService {
  static final SupabaseAuthService _instance = SupabaseAuthService._internal();
  final _supabase = Supabase.instance.client;

  factory SupabaseAuthService() {
    return _instance;
  }

  SupabaseAuthService._internal();

  late GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? ''
        : dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? '',
    serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '',
    scopes: ['email', 'profile'],
  );

  /// Sign in with Google using Supabase authentication
  Future<bool> signInWithGoogle() async {
    try {
      debugPrint('Starting Google Sign In with Supabase...');

      // Sign out first to ensure clean state
      await _googleSignIn.signOut();

      // Attempt Google sign in
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('Google Sign In cancelled by user');
        return false;
      }

      debugPrint('Google Sign In successful: ${googleUser.email}');

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('Missing Google authentication tokens');
        throw Exception('Failed to get Google authentication tokens');
      }

      debugPrint('Got Google tokens, signing in with Supabase...');
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );

      if (response.user == null) {
        debugPrint('Supabase authentication failed');
        throw Exception('Failed to authenticate with Supabase');
      }

      debugPrint('Supabase authentication successful: ${response.user!.email}');
      return true;
    } catch (error) {
      final errorString = error.toString();
      debugPrint('Google Sign In with Supabase failed');
      debugPrint('Error details: $error');

      if (errorString.contains('sign_in_failed') &&
          errorString.contains('10')) {
        debugPrint('Configuration Error - API Exception 10');
        debugPrint('This usually means:');
        debugPrint(
            '1. SHA-1 fingerprint not registered in Google Cloud Console');
        debugPrint('2. google-services.json file is invalid or missing');
        debugPrint('3. Package name mismatch');
        debugPrint('4. Google Sign-In not properly configured in Supabase');

        throw Exception('Google Sign-In configuration error. Please check:\n'
            '1. SHA-1 fingerprint in Google Cloud Console\n'
            '2. google-services.json file\n'
            '3. Package name configuration\n'
            '4. Supabase Google OAuth settings');
      }

      if (errorString.contains('popup_closed')) {
        debugPrint('Google Sign In popup closed by user');
        return false;
      }

      rethrow;
    }
  }

  /// Get current user from Supabase
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Convert Supabase User to AuthModel
  AuthModel? getAuthModel() {
    final user = getCurrentUser();
    final session = _supabase.auth.currentSession;
    if (user == null || session == null) return null;

    return AuthModel(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? '',
      token: session.accessToken,
      refreshToken: session.refreshToken ?? '',
    );
  }

  /// Check if user is logged in
  bool get isLoggedIn {
    return _supabase.auth.currentUser != null;
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    try {
      final session = _supabase.auth.currentSession;
      return session?.accessToken;
    } catch (e) {
      debugPrint('Error getting access token: $e');
      return null;
    }
  }

  /// Listen to authentication state changes
  Stream<AuthState> get onAuthStateChange {
    return _supabase.auth.onAuthStateChange;
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();

      // Sign out from Supabase
      await _supabase.auth.signOut();

      debugPrint('Sign out successful');
    } catch (error) {
      debugPrint('Sign out error: $error');
      rethrow;
    }
  }

  /// Print debug information
  Future<void> printDebugInfo() async {
    try {
      debugPrint('=== Supabase Auth Debug Info ===');
      debugPrint('Supabase URL: Available');
      debugPrint('Current user: ${getCurrentUser()?.email ?? 'None'}');
      debugPrint('Is logged in: $isLoggedIn');
      debugPrint('Google client ID: ${_googleSignIn.clientId ?? 'Default'}');
      debugPrint('Google scopes: ${_googleSignIn.scopes}');

      // Test Google sign in silently
      final silentUser = await _googleSignIn.signInSilently();
      debugPrint(
          'Google silent sign in result: ${silentUser?.email ?? 'Failed'}');
    } catch (e) {
      debugPrint('Debug info error: $e');
    }
  }

  /// Refresh session
  Future<AuthResponse?> refreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();
      return response;
    } catch (e) {
      debugPrint('Refresh session error: $e');
      return null;
    }
  }

  /// Update user profile
  Future<UserResponse?> updateUserProfile({
    String? email,
    String? phone,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(
          email: email,
          phone: phone,
          data: data,
        ),
      );
      return response;
    } catch (e) {
      debugPrint('Update profile error: $e');
      return null;
    }
  }

  /// Add logout method as alias for signOut for backward compatibility
  Future<void> logout() async {
    await signOut();
  }

  Future<ApiResponse<LoginModel>> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null && response.session != null) {
        final user = response.user!;
        final session = response.session!;
        final name = user.userMetadata?['name'] as String? ?? '';
        final email = user.email ?? '';
        final token = session.accessToken;
        final refreshToken = session.refreshToken ?? '';

        // Store tokens
        await StorageUtil.setAccessToken(token);
        await StorageUtil.setRefreshToken(refreshToken);

        return ApiResponse.success(
          LoginModel(
            id: user.id,
            name: name,
            email: email,
            token: token,
            refreshToken: refreshToken,
          ),
          message: 'Login successful',
        );
      } else {
        return ApiResponse.error('Login failed');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<LoginModel>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user != null && response.session != null) {
        final user = response.user!;
        final session = response.session!;
        return ApiResponse.success(
          LoginModel(
            id: user.id,
            name: name,
            email: email,
            token: session.accessToken,
            refreshToken: session.refreshToken ?? '',
          ),
          message: 'Registration successful',
        );
      } else {
        return ApiResponse.error('Registration failed');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<AuthModel> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user == null || response.session == null) {
        throw HttpException('Failed to create user');
      }

      return AuthModel(
        id: response.user!.id,
        name: name,
        email: email,
        token: response.session!.accessToken,
        refreshToken: response.session!.refreshToken ?? '',
      );
    } catch (e) {
      throw HttpException(e.toString());
    }
  }

  Future<AuthModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null || response.session == null) {
        throw HttpException('Failed to sign in');
      }

      return AuthModel(
        id: response.user!.id,
        name: response.user!.userMetadata?['name'] as String? ?? '',
        email: email,
        token: response.session!.accessToken,
        refreshToken: response.session!.refreshToken ?? '',
      );
    } catch (e) {
      throw HttpException(e.toString());
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw HttpException(e.toString());
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw HttpException(e.toString());
    }
  }

  Future<void> updateProfile({
    required String name,
    String? avatarUrl,
  }) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'name': name,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
          },
        ),
      );
    } catch (e) {
      throw HttpException(e.toString());
    }
  }
}
