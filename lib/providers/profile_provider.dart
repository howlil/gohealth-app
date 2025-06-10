
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/profile_model.dart';

class ProfileProvider extends ChangeNotifier {
  Profile? _profile;
  bool _isLoading = false;
  String? _error;

  // Getters
  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize profile
  Future<void> initializeProfile() async {
    _setLoading(true);
    try {
      // TODO: Implement API call to fetch profile
      // For now using mock data
      _profile = Profile(
        name: "John Doe",
        email: "john@example.com",
        photoUrl: null,
        gender: "Male",
        age: 25,
        height: 175,
        weight: 70,
        activityLevel: "Moderate",
        goal: "Maintain weight",
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Update profile
  Future<void> updateProfile(Profile updatedProfile) async {
    _setLoading(true);
    try {
      // TODO: Implement API call to update profile
      _profile = updatedProfile;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Update profile photo
  Future<void> updateProfilePhoto(XFile photo) async {
    _setLoading(true);
    try {
      // TODO: Implement API call to upload image
      _profile = _profile?.copyWith(photoUrl: photo.path);
      _error = null;
    } catch (e) {
      _error = e.toString();
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
