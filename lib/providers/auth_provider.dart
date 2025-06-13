import 'package:flutter/material.dart';
import '../models/auth_model.dart';
import '../models/register_model.dart';
import '../services/auth_service.dart';
import '../utils/storage_util.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthModel? _auth;
  bool _isLoading = false;
  String? _error;

  // Getters
  AuthModel? get auth => _auth;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _auth != null;

  // Initialize auth state
  Future<void> initializeAuth() async {
    _setLoading(true);
    _clearError();

    try {
      final token = await StorageUtil.getAccessToken();
      if (token != null) {
        final userData = await StorageUtil.getUserData();
        if (userData != null) {
          _auth = AuthModel.fromJson(userData);
        }
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (email.isEmpty || password.isEmpty) {
        _error = 'Please enter both email and password';
        return false;
      }

      final response = await _authService.login(email, password);

      if (response.success && response.data != null) {
        _auth = response.data;
        await StorageUtil.setAccessToken(response.data!.token);
        await StorageUtil.setUserData(response.data!.toJson());
        _error = null;
        return true;
      } else {
        _error = response.message;
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register
  Future<bool> register(RegisterModel registerData) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.register(registerData);
      if (response?.success == true && response?.data != null) {
        _auth = response!.data;
        await StorageUtil.setAccessToken(response.data!.token);
        await StorageUtil.setUserData(response.data!.toJson());
        debugPrint('Registration successful');
        return true;
      } else {
        _error = response?.message ?? 'Registration failed';
        debugPrint('Registration failed: $_error');
        return false;
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    _clearError();

    try {
      await StorageUtil.clearAll();
      _auth = null;
      debugPrint('Logout successful');
    } catch (e) {
      debugPrint('Logout error: $e');
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Google Sign In
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      // TODO: Implement Google Sign In
      return false;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Clear error
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
