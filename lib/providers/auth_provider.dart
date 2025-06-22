import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../models/auth_model.dart';
import '../utils/storage_util.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

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
      final isAuthenticated = await _authService.isAuthenticated();
      _isLoggedIn = isAuthenticated;

      if (isAuthenticated) {
        final userData = await _authService.getCurrentUser();
        if (userData != null) {
          _user = AuthModel(
            id: userData['id'] ?? '',
            name: userData['name'] ?? '',
            email: userData['email'] ?? '',
            profileImage: userData['profileImage'],
            token: await StorageUtil.getAccessToken() ?? '',
            refreshToken: await StorageUtil.getRefreshToken() ?? '',
          );

          // Send FCM token to server for existing authenticated user
          FCMService().sendTokenToServer().catchError((error) {
            // Error handled
          });
        }
      }
    } catch (e) {
      _error = e.toString();
      _isLoggedIn = false;
    } finally {
      _setLoading(false);
    }
  }

  // Login with email and password
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.login(email, password);

      if (user != null) {
        _user = user;
        _isLoggedIn = true;

        // Send FCM token to server after successful login
        FCMService().sendTokenToServer().catchError((error) {
          // Error handled
        });

        return true;
      } else {
        _error = 'Login failed. Please check your credentials.';
        return false;
      }
    } catch (e) {
      _error = e.toString();
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
      final user = await _authService.register(name, email, password);

      if (user != null) {
        // Check if user has valid tokens (successful auto-login after registration)
        if (user.token.isNotEmpty && user.refreshToken.isNotEmpty) {
          _user = user;
          _isLoggedIn = true;

          // Send FCM token to server after successful registration
          FCMService().sendTokenToServer().catchError((error) {
            // Error handled
          });

          return true;
        } else {
          // Registration successful but auto-login failed
          // User needs to login manually
          _user = null;
          _isLoggedIn = false;
          _error =
              'Registration successful! Please login with your credentials.';
          return true; // Return true because registration was successful
        }
      } else {
        _error = 'Registration failed. Please try again.';
        return false;
      }
    } catch (e) {
      _error = e.toString();
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
      final success = await _authService.logout();

      if (success) {
        _user = null;
        _isLoggedIn = false;
        return true;
      } else {
        _error = 'Logout failed. Please try again.';
        return false;
      }
    } catch (e) {
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
