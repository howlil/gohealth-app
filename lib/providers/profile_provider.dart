import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/profile_model.dart';
import '../models/user_profile_model.dart';
import '../services/user_service.dart';
import '../utils/http_exception.dart';

class ProfileProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  Profile? _profile;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // Initialize profile from API
  Future<void> initializeProfile() async {
    if (_isInitialized) return;

    _setLoading(true);
    _clearError();

    try {
      debugPrint('Initializing profile...');

      // Try to get current user profile
      final userProfileResponse = await _userService.getCurrentUser();

      if (userProfileResponse != null &&
          userProfileResponse.success &&
          userProfileResponse.data != null) {
        // Convert UserProfileData to Profile
        _profile = Profile(
          id: userProfileResponse.data!.id,
          name: userProfileResponse.data!.name,
          email: userProfileResponse.data!.email,
          photoUrl: userProfileResponse.data!.profileImage,
          gender: userProfileResponse.data!.gender ?? 'MALE',
          age: userProfileResponse.data!.age ?? 25,
          height: userProfileResponse.data!.height ?? 170.0,
          weight: userProfileResponse.data!.weight ?? 70.0,
          activityLevel:
              userProfileResponse.data!.activityLevel ?? 'MODERATELY_ACTIVE',
        );

        _isInitialized = true;
        debugPrint('Profile initialized successfully');
      } else {
        _error = userProfileResponse?.message ?? 'Failed to load profile';
        debugPrint('Error initializing profile: $_error');
      }
    } on HttpException catch (e) {
      _error = e.message;
      debugPrint('HTTP error initializing profile: $e');
    } catch (e) {
      _error = e.toString();
      debugPrint('Error initializing profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update profile via API
  Future<bool> updateProfile(Profile updatedProfile) async {
    _setLoading(true);
    _clearError();

    try {
      // Convert Profile to UserProfileData
      final userProfileData = UserProfileData(
        id: updatedProfile.id ?? '',
        name: updatedProfile.name,
        email: updatedProfile.email,
        age: updatedProfile.age,
        gender: updatedProfile.gender,
        height: updatedProfile.height,
        weight: updatedProfile.weight,
        activityLevel: updatedProfile.activityLevel,
        profileImage: updatedProfile.photoUrl,
        token: '', // Token will be handled by the service
      );

      final response = await _userService.updateProfile(userProfileData);
      if (response?.success == true && response?.data != null) {
        // Convert UserProfileData back to Profile
        _profile = Profile(
          id: response!.data!.id,
          name: response.data!.name,
          email: response.data!.email,
          photoUrl: response.data!.profileImage,
          gender: response.data!.gender ?? 'MALE',
          age: response.data!.age ?? 25,
          height: response.data!.height ?? 170.0,
          weight: response.data!.weight ?? 70.0,
          activityLevel: response.data!.activityLevel ?? 'MODERATELY_ACTIVE',
        );
        debugPrint('Profile updated successfully');
        return true;
      } else {
        _error = response?.message ?? 'Failed to update profile';
        debugPrint('Error updating profile: $_error');
        return false;
      }
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

      if (userProfileResponse != null &&
          userProfileResponse.success &&
          userProfileResponse.data != null) {
        // Convert UserProfileData to Profile
        _profile = Profile(
          id: userProfileResponse.data!.id,
          name: userProfileResponse.data!.name,
          email: userProfileResponse.data!.email,
          photoUrl: userProfileResponse.data!.profileImage,
          gender: userProfileResponse.data!.gender ?? 'MALE',
          age: userProfileResponse.data!.age ?? 25,
          height: userProfileResponse.data!.height ?? 170.0,
          weight: userProfileResponse.data!.weight ?? 70.0,
          activityLevel:
              userProfileResponse.data!.activityLevel ?? 'MODERATELY_ACTIVE',
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
