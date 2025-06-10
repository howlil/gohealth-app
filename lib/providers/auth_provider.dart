import 'package:flutter/material.dart';
import 'package:gohealth/models/auth_model.dart';
import 'package:gohealth/services/auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthModel? _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _isInitialized = false;
  String? _error;
  AuthStatus _status = AuthStatus.initial;

  // Getters
  AuthModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  AuthStatus get status => _status;

  // Initialize auth state
  Future<void> init() async {
    if (_isInitialized) return;

    _setLoading(true);
    _setStatus(AuthStatus.loading);

    try {
      _isLoggedIn = await _authService.isLoggedIn();
      if (_isLoggedIn) {
        _user = await _authService.getStoredUser();
        final currentUser = await _authService.getCurrentUser();
        if (currentUser != null) {
          _user = currentUser;
          _setStatus(AuthStatus.authenticated);
        } else {
          _setStatus(AuthStatus.unauthenticated);
        }
      } else {
        _setStatus(AuthStatus.unauthenticated);
      }
      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
      _setStatus(AuthStatus.error);
      debugPrint('Auth initialization error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    _setStatus(AuthStatus.loading);

    try {
      final GoogleSignInAccount? googleUser =
          await _authService.signInWithGoogle();

      if (googleUser != null) {
        // Create AuthModel from GoogleSignInAccount
        _user = AuthModel(
          id: googleUser.id,
          email: googleUser.email,
          name: googleUser.displayName ?? '',
          photoUrl: googleUser.photoUrl,
        );

        _isLoggedIn = true;
        _setStatus(AuthStatus.authenticated);
        return true;
      }

      _setStatus(AuthStatus.unauthenticated);
      return false;
    } catch (e) {
      _error = e.toString();
      _setStatus(AuthStatus.error);
      debugPrint('Google sign in error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    _setStatus(AuthStatus.loading);

    try {
      await _authService.logout();
      _user = null;
      _isLoggedIn = false;
      _setStatus(AuthStatus.unauthenticated);
      _clearError();
    } catch (e) {
      _error = e.toString();
      _setStatus(AuthStatus.error);
      debugPrint('Logout error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get current user
  Future<void> getCurrentUser() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser != null) {
        _user = currentUser;
        _setStatus(AuthStatus.authenticated);
      } else {
        _setStatus(AuthStatus.unauthenticated);
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setStatus(AuthStatus.error);
      debugPrint('Get current user error: $e');
      notifyListeners();
    }
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }
}

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}
