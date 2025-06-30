import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../services/data_sync_service.dart';
import '../models/auth_model.dart';
import '../utils/storage_util.dart';
import '../dao/user_dao.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DataSyncService _dataSyncService = DataSyncService();
  final UserDao _userDao = UserDao();

  AuthModel? _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _error;

  // Getters
  AuthModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get error => _error;

  // Constructor - check if user is already logged in
  AuthProvider() {
    _checkLoginStatus();
  }

  // Check if user is already logged in
  Future<void> _checkLoginStatus() async {
    _setLoading(true);
    _clearError();

    try {
      // Add timeout to prevent infinite loading
      final isAuthenticated = await _authService
          .isAuthenticated()
          .timeout(const Duration(seconds: 10));
      _isLoggedIn = isAuthenticated;

      if (isAuthenticated) {
        final userData = await _authService
            .getCurrentUser()
            .timeout(const Duration(seconds: 10));
        if (userData != null) {
          _user = AuthModel(
            id: userData['id'] ?? '',
            name: userData['name'] ?? '',
            email: userData['email'] ?? '',
            profileImage: userData['profileImage'],
            token: await StorageUtil.getAccessToken() ?? '',
            refreshToken: await StorageUtil.getRefreshToken() ?? '',
          );

          // Initialize data sync service
          try {
            await _dataSyncService.initialize();
            debugPrint(
                '✅ AuthProvider: Data sync service initialized for existing session');
          } catch (e) {
            debugPrint('⚠️ AuthProvider: Data sync initialization failed: $e');
          }

          // FCM token will be sent when user reaches homepage
          debugPrint(
              '✅ AuthProvider: User already authenticated, FCM token will be sent from homepage');
        }
      }
    } catch (e) {
      debugPrint('AuthProvider._checkLoginStatus error: $e');
      _error = e.toString();
      _isLoggedIn = false;
    } finally {
      _setLoading(false);
    }
  }

  // Clear old user data
  Future<void> clearOldUserData() async {
    try {
      debugPrint('🗑️ AuthProvider: Clearing old user data');

      // Clear local database
      await _userDao.clearAllData();

      // Clear SharedPreferences user data (but keep tokens)
      await StorageUtil.clearUserData();

      debugPrint('✅ AuthProvider: Old user data cleared');
    } catch (e) {
      debugPrint('❌ AuthProvider: Error clearing old data: $e');
    }
  }

  // Login with email and password
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('🔄 AuthProvider: Starting login process for $email');

      // Clear old user data first
      await clearOldUserData();

      final user = await _authService
          .login(email, password)
          .timeout(const Duration(seconds: 30));

      if (user != null) {
        debugPrint('✅ AuthProvider: Login successful for ${user.email}');
        _user = user;
        _isLoggedIn = true;

        // Initialize data sync service after successful login
        try {
          await _dataSyncService.initialize();
          debugPrint('✅ AuthProvider: Data sync service initialized');
        } catch (e) {
          debugPrint('⚠️ AuthProvider: Data sync initialization failed: $e');
        }

        // FCM token will be sent when user reaches homepage
        debugPrint(
            '✅ AuthProvider: Login successful, FCM token will be sent from homepage');

        return true;
      } else {
        debugPrint('❌ AuthProvider: Login returned null user');
        _error = 'Login failed. Please check your credentials.';
        return false;
      }
    } catch (e) {
      debugPrint('❌ AuthProvider.login error: $e');

      // Extract and format error message
      String errorMessage = e.toString();
      if (errorMessage.contains('HttpException:')) {
        errorMessage = errorMessage.replaceFirst('HttpException: ', '');
      }

      _error = errorMessage;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register new account
  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('🔄 AuthProvider: Starting registration process for $email');

      // Clear old user data first
      await clearOldUserData();

      final user = await _authService
          .register(name, email, password)
          .timeout(const Duration(seconds: 30));

      if (user != null) {
        debugPrint('✅ AuthProvider: Registration successful for ${user.email}');

        // Check if user has valid tokens (successful auto-login after registration)
        if (user.token.isNotEmpty && user.refreshToken.isNotEmpty) {
          debugPrint(
              '✅ AuthProvider: Auto-login successful after registration');
          _user = user;
          _isLoggedIn = true;

          // Initialize data sync service after successful registration
          try {
            await _dataSyncService.initialize();
            debugPrint(
                '✅ AuthProvider: Data sync service initialized after registration');
          } catch (e) {
            debugPrint(
                '⚠️ AuthProvider: Data sync initialization failed after registration: $e');
          }

          // FCM token will be sent when user reaches homepage
          debugPrint(
              '✅ AuthProvider: Registration with auto-login successful, FCM token will be sent from homepage');

          return true;
        } else {
          // Registration successful but no auto-login - TETAP DI HALAMAN REGISTER
          debugPrint(
              '✅ AuthProvider: Registration successful but staying on register page');
          _user = null;
          _isLoggedIn = false; // PENTING: pastikan false agar tidak redirect

          // Jangan set error karena registration berhasil
          return true;
        }
      } else {
        debugPrint('❌ AuthProvider: Registration returned null user');
        _error = 'Registration failed. Please try again.';
        return false;
      }
    } catch (e) {
      debugPrint('❌ AuthProvider.register error: $e');

      // Extract and format error message
      String errorMessage = e.toString();
      if (errorMessage.contains('HttpException:')) {
        errorMessage = errorMessage.replaceFirst('HttpException: ', '');
      }

      _error = errorMessage;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<bool> logout() async {
    _setLoading(true);
    _clearError();

    try {
      final success =
          await _authService.logout().timeout(const Duration(seconds: 30));

      if (success) {
        // Clear old user data
        await clearOldUserData();

        _user = null;
        _isLoggedIn = false;

        // Dispose data sync service
        _dataSyncService.dispose();

        return true;
      } else {
        _error = 'Logout failed. Please try again.';
        return false;
      }
    } catch (e) {
      debugPrint('AuthProvider.logout error: $e');
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Request password reset
  Future<bool> requestPasswordReset(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.requestPasswordReset(email);

      if (!success) {
        _error = 'Failed to send password reset email. Please try again.';
      }

      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reset password with token
  Future<bool> resetPassword(String token, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.resetPassword(token, password);

      if (!success) {
        _error = 'Failed to reset password. Please try again.';
      }

      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile image after successful upload
  void updateProfileImage(String imageUrl) {
    if (_user != null) {
      _user = _user!.copyWith(profileImage: imageUrl);
      notifyListeners();
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clear error
  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
