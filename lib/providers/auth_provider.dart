import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(AuthService());
});

class AuthState {
  final bool isAuthenticated;
  final User? user;
  final String? accessToken;
  final String? refreshToken;
  final bool isLoading;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    User? user,
    String? accessToken,
    String? refreshToken,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final _prefs = SharedPreferences.getInstance();

  AuthNotifier(this._authService) : super(AuthState()) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final prefs = await _prefs;
    final token = prefs.getString('accessToken');
    if (token != null) {
      state = state.copyWith(
        isAuthenticated: true,
        accessToken: token,
        refreshToken: prefs.getString('refreshToken'),
      );
      await getCurrentUser();
    }
  }

  Future<void> googleAuth(String idToken) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await _authService.googleAuth(idToken);
      await _saveAuthData(response);
      state = state.copyWith(
        isAuthenticated: true,
        user: response.user,
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshToken() async {
    try {
      if (state.refreshToken == null) return;
      
      final response = await _authService.refreshToken(state.refreshToken!);
      await _saveAuthData(response);
      state = state.copyWith(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
    } catch (e) {
      await logout();
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } finally {
      await _clearAuthData();
      state = AuthState();
    }
  }

  Future<void> getCurrentUser() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final user = await _authService.getCurrentUser();
      state = state.copyWith(
        user: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _saveAuthData(AuthResponse response) async {
    final prefs = await _prefs;
    await prefs.setString('accessToken', response.accessToken);
    await prefs.setString('refreshToken', response.refreshToken);
  }

  Future<void> _clearAuthData() async {
    final prefs = await _prefs;
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
  }
} 