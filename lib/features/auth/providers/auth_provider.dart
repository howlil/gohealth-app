import 'package:flutter/material.dart';
import 'dart:async';
import '../models/auth_models.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier implements Listenable {
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
      debugPrint('Initializing auth provider');
      
      // Use compute for heavy operations
      await Future.wait([
        _initializeAuthState(),
        _preloadUserData(),
      ], eagerError: true);
      
      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Auth initialization error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _initializeAuthState() async {
    _isLoggedIn = await _authService.isLoggedIn();
    debugPrint('User is logged in: $_isLoggedIn');
  }

  Future<void> _preloadUserData() async {
    if (_isLoggedIn) {
      try {
        _user = await _authService.getStoredUser();
        debugPrint('Loaded user: ${_user?.name}');
        
        // Try to refresh user data in background
        unawaited(_refreshUserData());
      } catch (e) {
        debugPrint('Error preloading user data: $e');
      }
    }
  }

  Future<void> _refreshUserData() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser != null) {
        _user = currentUser;
        debugPrint('Updated user data: ${_user?.name}');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    // Clear previous errors
    _clearError();
    _setLoading(true);
    
    try {
      debugPrint('Starting Google sign in');
      final authResponse = await _authService.signInWithGoogle();
      
      if (authResponse != null) {
        debugPrint('Sign in successful: ${authResponse.data.user.name}');
        _user = authResponse.data.user;
        _isLoggedIn = true;
        notifyListeners();
        return true;
      } else {
        debugPrint('Sign in cancelled by user');
        _error = 'Sign in was cancelled';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Google sign in error: $e');
      _error = 'Failed to sign in: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      debugPrint('Logging out user');
      await _authService.logout();
      _user = null;
      _isLoggedIn = false;
      _clearError();
      debugPrint('Logout successful');
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
      debugPrint('Getting current user data');
      final currentUser = await _authService.getCurrentUser();
      if (currentUser != null) {
        _user = currentUser;
        debugPrint('Updated user data: ${_user?.name}');
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Get current user error: $e');
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