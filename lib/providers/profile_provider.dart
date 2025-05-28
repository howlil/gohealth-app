import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_model.dart';

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});

class ProfileState {
  final ProfileModel? profile;
  final bool isLoading;
  final String? error;

  ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    ProfileModel? profile,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(ProfileState());

  Future<void> fetchProfile() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // TODO: Implement API call to fetch profile

      // Temporary mock data
      final profile = ProfileModel(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        phoneNumber: '+1234567890',
        address: '123 Main St',
        photoUrl: null,
      );

      state = state.copyWith(
        profile: profile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phoneNumber,
    String? address,
    String? photoUrl,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      if (state.profile == null) throw Exception('Profile not initialized');

      // TODO: Implement API call to update profile

      final updatedProfile = state.profile!.copyWith(
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        address: address,
        photoUrl: photoUrl,
      );

      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> uploadProfileImage(File image) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      if (state.profile == null) throw Exception('Profile not initialized');

      // TODO: Implement API call to upload image
      // For now, we'll just simulate a delay
      await Future.delayed(const Duration(seconds: 1));

      // Simulate getting back a URL
      const mockImageUrl = 'https://example.com/profile.jpg';

      final updatedProfile = state.profile!.copyWith(
        photoUrl: mockImageUrl,
      );

      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> logout() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // TODO: Implement API call to logout
      // For now, we'll just simulate a delay
      await Future.delayed(const Duration(seconds: 1));

      state = ProfileState(); // Reset state to initial
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }
}
