import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/profile_model.dart';
import '../models/user_profile_model.dart';
import '../models/local_user_model.dart';
import '../services/user_service.dart';
import '../services/local_user_service.dart';
import '../utils/http_exception.dart';

class ProfileProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  final LocalUserService _localUserService = LocalUserService();

  Profile? _profile;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // Initialize profile from local storage or API
  Future<void> initializeProfile() async {
    if (_isInitialized) return;

    _setLoading(true);
    _clearError();

    try {
      debugPrint('Initializing profile...');

      // Try to get user from local storage first
      final localUser = await _localUserService.getUserProfile();

      if (localUser != null) {
        // Convert LocalUser to Profile
        _profile = _localUserToProfile(localUser);
        _isInitialized = true;
        debugPrint('Profile initialized from local storage');

        // Try to refresh from server in background
        _refreshFromServerInBackground();
      } else {
        // Fallback to server if no local data
        await _loadFromServer();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error initializing profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load profile from server and save locally
  Future<void> _loadFromServer() async {
    try {
      final userProfileResponse = await _userService.getCurrentUser();

      if (userProfileResponse?.success == true &&
          userProfileResponse?.data != null) {
        final userData = userProfileResponse!.data;

        // Save to local storage
        await _localUserService.saveUserLocally(
          id: userData.id,
          name: userData.name ?? '',
          email: userData.email ?? '',
          age: userData.age,
          height: userData.height,
          weight: userData.weight,
          profileImage: userData.profileImage,
        );

        // Convert to Profile model
        _profile = Profile(
          id: userData.id,
          name: userData.name,
          email: userData.email,
          photoUrl: userData.profileImage,
          gender: userData.gender ?? 'MALE',
          age: userData.age ?? 25,
          height: userData.height ?? 170.0,
          weight: userData.weight ?? 70.0,
          activityLevel: userData.activityLevel ?? 'MODERATELY_ACTIVE',
          bmr: userData.bmr,
          tdee: userData.tdee,
        );

        _isInitialized = true;
        debugPrint('Profile loaded from server and cached locally');
      } else {
        _error = userProfileResponse?.message ?? 'Failed to load profile';
        debugPrint('Error loading profile from server: $_error');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading from server: $e');
    }
  }

  // Background refresh from server
  Future<void> _refreshFromServerInBackground() async {
    try {
      debugPrint('Refreshing profile from server in background...');

      final localUser = await _localUserService.loadUserFromServer();
      if (localUser != null) {
        _profile = _localUserToProfile(localUser);
        notifyListeners();
        debugPrint('Profile refreshed from server');
      }
    } catch (e) {
      debugPrint('Background refresh failed: $e');
      // Don't show error to user for background refresh
    }
  }

  // Convert LocalUser to Profile model
  Profile _localUserToProfile(LocalUser localUser) {
    return Profile(
      id: localUser.id,
      name: localUser.name,
      email: localUser.email,
      photoUrl: localUser.profileImage,
      gender: 'MALE', // Default value since LocalUser doesn't have gender
      age: localUser.age ?? 25,
      height: localUser.height ?? 170.0,
      weight: localUser.weight ?? 70.0,
      activityLevel: 'MODERATELY_ACTIVE', // Default value
      bmr: null, // Will be calculated if needed
      tdee: null, // Will be calculated if needed
    );
  }

  // Update profile via API and local storage
  Future<bool> updateProfile(Profile updatedProfile) async {
    _setLoading(true);
    _clearError();

    try {
      // Update local storage first (for instant UI update)
      if (updatedProfile.id != null) {
        await _localUserService.updateUserProfile(
          userId: updatedProfile.id!,
          name: updatedProfile.name,
          age: updatedProfile.age,
          height: updatedProfile.height,
          weight: updatedProfile.weight,
          profileImage: updatedProfile.photoUrl,
        );

        // Update local profile state
        _profile = updatedProfile;
        notifyListeners();
        debugPrint('Profile updated in local storage');
      }

      // Then sync with server (local service will handle sync automatically)
      // Convert Profile to UserProfileData for server update
      final userProfileData = UserProfileData(
        id: updatedProfile.id ?? '',
        name: updatedProfile.name,
        email: updatedProfile.email,
        age: updatedProfile.age,
        height: updatedProfile.height,
        weight: updatedProfile.weight,
        gender: updatedProfile.gender,
        activityLevel: updatedProfile.activityLevel,
        profileImage: updatedProfile.photoUrl,
        bmr: updatedProfile.bmr,
        tdee: updatedProfile.tdee,
      );

      try {
        final response = await _userService.updateProfile(userProfileData);
        if (response?.success == true) {
          debugPrint('Profile synced with server successfully');
        } else {
          debugPrint('Failed to sync with server: ${response?.message}');
          // Still return true because local update succeeded
        }
      } catch (serverError) {
        debugPrint('Server sync failed: $serverError');
        // Still return true because local update succeeded
      }

      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update profile photo via API
  Future<bool> updateProfilePhoto(XFile photo) async {
    _setLoading(true);
    _clearError();

    try {
      final file = File(photo.path);
      final response = await _userService.uploadProfileImage(file);
      if (response?.success == true && response?.data != null) {
        _profile = _profile?.copyWith(photoUrl: response!.data);
        debugPrint('Profile photo updated successfully');
        return true;
      } else {
        _error = response?.message ?? 'Failed to upload image';
        debugPrint('Error updating profile photo: $_error');
        return false;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating profile photo: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh profile data
  Future<void> refreshProfile() async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('Refreshing profile...');

      // Try to get current user profile
      final userProfileResponse = await _userService.getCurrentUser();

      if (userProfileResponse?.success == true &&
          userProfileResponse?.data != null) {
        // Convert UserProfileData to Profile
        _profile = Profile(
          id: userProfileResponse!.data.id,
          name: userProfileResponse.data.name,
          email: userProfileResponse.data.email,
          photoUrl: userProfileResponse.data.profileImage,
          gender: userProfileResponse.data.gender ?? 'MALE',
          age: userProfileResponse.data.age ?? 25,
          height: userProfileResponse.data.height ?? 170.0,
          weight: userProfileResponse.data.weight ?? 70.0,
          activityLevel:
              userProfileResponse.data.activityLevel ?? 'MODERATELY_ACTIVE',
          bmr: userProfileResponse.data.bmr,
          tdee: userProfileResponse.data.tdee,
        );

        debugPrint('Profile refreshed successfully');
      } else {
        _error = userProfileResponse?.message ?? 'Failed to refresh profile';
        debugPrint('Error refreshing profile: $_error');
      }
    } on HttpException catch (e) {
      _error = e.message;
      debugPrint('HTTP error refreshing profile: $e');
    } catch (e) {
      _error = e.toString();
      debugPrint('Error refreshing profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update gender
  void updateGender(String gender) {
    if (_profile != null) {
      _profile = _profile!.copyWith(gender: gender);
      notifyListeners();
    }
  }

  // Update activity level
  void updateActivityLevel(String level) {
    if (_profile != null) {
      _profile = _profile!.copyWith(activityLevel: level);
      notifyListeners();
    }
  }

  // Update age
  void updateAge(int age) {
    if (_profile != null) {
      _profile = _profile!.copyWith(age: age);
      notifyListeners();
    }
  }

  // Update height
  void updateHeight(double height) {
    if (_profile != null) {
      _profile = _profile!.copyWith(height: height);
      notifyListeners();
    }
  }

  // Update weight
  void updateWeight(double weight) {
    if (_profile != null) {
      _profile = _profile!.copyWith(weight: weight);
      notifyListeners();
    }
  }

  // Update goal
  void updateGoal(String goal) {
    if (_profile != null) {
      _profile = _profile!.copyWith(goal: goal);
      notifyListeners();
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
