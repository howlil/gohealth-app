import 'package:flutter/material.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _isInitialized = false;
  String? _error;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  // Initialize auth state
  Future<void> init() async {
    if (_isInitialized) return; // Prevent multiple initialization
    
    _setLoading(true);
    
    try {
      _isLoggedIn = await _authService.isLoggedIn();
      if (_isLoggedIn) {
        _user = await _authService.getStoredUser();
        // Try to refresh user data
        final currentUser = await _authService.getCurrentUser();
        if (currentUser != null) {
          _user = currentUser;
        }
      }
      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Auth initialization error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final authResponse = await _authService.signInWithGoogle();
      if (authResponse != null) {
        _user = authResponse.data.user;
        _isLoggedIn = true;
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('Google sign in error: $e');
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await _authService.logout();
      _user = null;
      _isLoggedIn = false;
      _clearError();
    } catch (e) {
      _error = e.toString();
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
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
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
}