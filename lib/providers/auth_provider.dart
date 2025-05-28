import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  Future<void> checkAuthStatus() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // TODO: Implement actual auth status check
      // For now, we'll simulate a check
      await Future.delayed(const Duration(seconds: 1));

      // Simulate being logged out
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        user: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
        isAuthenticated: false,
      );
    }
  }

  Future<void> login(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // TODO: Implement actual login
      await Future.delayed(const Duration(seconds: 1));

      // Simulate successful login
      final user = User(
        id: '1',
        name: 'John Doe',
        email: email,
        isVerified: true,
      );

      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
        isAuthenticated: false,
      );
    }
  }

  Future<void> logout() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // TODO: Implement actual logout
      await Future.delayed(const Duration(seconds: 1));

      state = AuthState(); // Reset to initial state
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // TODO: Implement actual registration
      await Future.delayed(const Duration(seconds: 1));

      // Simulate successful registration
      final user = User(
        id: '1',
        name: name,
        email: email,
        isVerified: false,
      );

      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }
}
