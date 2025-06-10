import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/profile_model.dart';
import '../services/user_service.dart';

class ProfileProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  Profile? _profile;
  bool _isLoading = false;
  String? _error;

  // Getters
  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize profile from API
  Future<void> initializeProfile() async {
    _setLoading(true);
    try {
      final response = await _userService.getProfile();
      if (response?.success == true && response?.data != null) {
        _profile = response!.data;
        _error = null;
      } else {
        _error = response?.message ?? 'Failed to load profile';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Update profile via API
  Future<bool> updateProfile(Profile updatedProfile) async {
    _setLoading(true);
    try {
      final response = await _userService.updateProfile(updatedProfile);
      if (response?.success == true && response?.data != null) {
        _profile = response!.data;
        _error = null;
        return true;
      } else {
        _error = response?.message ?? 'Failed to update profile';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update profile photo via API
  Future<bool> updateProfilePhoto(XFile photo) async {
    _setLoading(true);
    try {
      final file = File(photo.path);
      final response = await _userService.uploadProfileImage(file);
      if (response?.success == true && response?.data != null) {
        _profile = _profile?.copyWith(photoUrl: response!.data);
        _error = null;
        return true;
      } else {
        _error = response?.message ?? 'Failed to upload image';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
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

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    try {
      // TODO: Implement API call to logout
      _profile = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
