import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/profile_model.dart';
import '../models/user_profile_model.dart';
import '../models/local_user_model.dart';
import '../services/user_service.dart';
import '../services/local_user_service.dart';
import '../services/data_sync_service.dart';
import '../dao/user_dao.dart';
import '../utils/http_exception.dart';
import 'base_provider.dart';

class ProfileProvider extends BaseProvider {
  final UserService _userService = UserService();
  final LocalUserService _localUserService = LocalUserService();
  final DataSyncService _dataSyncService = DataSyncService();
  final UserDao _userDao = UserDao();

  Profile? _profile;
  bool _isInitialized = false;

  // Getters
  Profile? get profile => _profile;
  bool get isInitialized => _isInitialized;

  // Initialize profile from local storage or API
  Future<void> initializeProfile() async {
    if (_isInitialized) return;

    setLoading(true);
    clearMessages();

    try {
      debugPrint('Initializing profile...');

      // Force refresh from server to ensure we have the latest data for current user
      if (await _dataSyncService.hasInternetConnection()) {
        await _loadFromServer();
      } else {
        // Only use local data if no internet connection
        final localUser = await _dataSyncService.getCurrentUser();
        if (localUser != null) {
          // Validate that local user matches current session
          final session = await _userDao.getActiveSession();
          if (session != null && localUser.id == session.userId) {
            _profile = _localUserToProfile(localUser);
            _isInitialized = true;
            debugPrint('Profile initialized from validated local storage');
            setSuccess('Profil dimuat dari cache lokal');
          } else {
            setError('Data lokal tidak cocok dengan sesi aktif');
          }
        } else {
          setError('Tidak ada koneksi internet dan data lokal tidak ditemukan');
        }
      }
    } catch (e) {
      setError('Gagal memuat profil: ${e.toString()}');
      debugPrint('Error initializing profile: $e');
    } finally {
      setLoading(false);
    }
  }

  // Load profile from server and save locally
  Future<void> _loadFromServer() async {
    try {
      debugPrint('Loading profile from server...');

      final userProfileResponse = await _userService.getCurrentUser();

      if (userProfileResponse?.success == true &&
          userProfileResponse?.data != null) {
        final userData = userProfileResponse!.data;

        // Save to local storage with proper session validation
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
        debugPrint(
            'Profile loaded from server and cached locally for user: ${userData.email}');
        setSuccess('Profil berhasil dimuat dari server');
      } else {
        final errorMessage =
            userProfileResponse?.message ?? 'Gagal memuat profil dari server';
        debugPrint('Error loading profile from server: $errorMessage');
        setError(errorMessage);
      }
    } catch (e) {
      debugPrint('Error loading from server: $e');
      setError('Gagal terhubung ke server: ${e.toString()}');
    }
  }

  // Convert LocalUser to Profile model with validation
  Profile _localUserToProfile(LocalUser localUser) {
    return Profile(
      id: localUser.id,
      name: localUser.name,
      email: localUser.email,
      photoUrl: localUser.profileImage,
      gender: 'MALE', // Default value since LocalUser doesn't have gender field
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
    setLoading(true);
    clearMessages();

    try {
      if (updatedProfile.id == null || updatedProfile.id!.isEmpty) {
        debugPrint('Profile ID is null or empty, cannot update');
        setError('ID profil tidak valid, tidak dapat memperbarui profil');
        return false;
      }

      debugPrint('Updating profile for user: ${updatedProfile.id}');

      // First, try to update via API
      bool serverUpdateSuccess = false;
      if (await _dataSyncService.hasInternetConnection()) {
        try {
          // Convert Profile to UserProfileData for API
          final profileData = UserProfileData(
            id: updatedProfile.id!,
            name: updatedProfile.name,
            email: updatedProfile.email,
            age: updatedProfile.age,
            height: updatedProfile.height,
            weight: updatedProfile.weight,
            gender: updatedProfile.gender,
            activityLevel: updatedProfile.activityLevel,
          );

          final response = await _userService.updateProfile(profileData);
          serverUpdateSuccess = response?.success == true;

          if (serverUpdateSuccess) {
            debugPrint('✅ Profile updated successfully on server');
          } else {
            debugPrint('⚠️ Server update failed: ${response?.message}');
          }
        } catch (e) {
          debugPrint('⚠️ Server update error: $e');
        }
      }

      // Update local storage regardless (for offline capability)
      final localUpdateSuccess = await _dataSyncService.updateUserData(
        userId: updatedProfile.id!,
        name: updatedProfile.name,
        age: updatedProfile.age,
        height: updatedProfile.height,
        weight: updatedProfile.weight,
        profileImage: updatedProfile.photoUrl,
        syncToServer:
            !serverUpdateSuccess, // Only queue for sync if server update failed
      );

      if (localUpdateSuccess) {
        // Update local profile state immediately
        _profile = updatedProfile;
        notifyListeners();

        if (serverUpdateSuccess) {
          debugPrint('✅ Profile updated successfully (server + local)');
          setSuccess('Profil berhasil diperbarui');
        } else {
          debugPrint('✅ Profile updated locally, will sync to server later');
          setSuccess('Profil berhasil diperbarui secara lokal');
        }
        return true;
      } else {
        setError('Gagal memperbarui profil. Silakan coba lagi.');
        return false;
      }
    } catch (e) {
      setError('Terjadi kesalahan saat memperbarui profil: ${e.toString()}');
      debugPrint('Error updating profile: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Update profile photo via API
  Future<bool> updateProfilePhoto(XFile photo) async {
    setLoading(true);
    clearMessages();

    try {
      final file = File(photo.path);
      final response = await _userService.uploadProfileImage(file);

      if (response?.success == true && response?.data != null) {
        _profile = _profile?.copyWith(photoUrl: response!.data);
        debugPrint('Profile photo updated successfully');
        setSuccess('Foto profil berhasil diperbarui');
        return true;
      } else {
        final errorMessage =
            response?.message ?? 'Gagal mengupload foto profil';
        debugPrint('Error updating profile photo: $errorMessage');
        setError(errorMessage);
        return false;
      }
    } catch (e) {
      setError('Terjadi kesalahan saat mengupload foto: ${e.toString()}');
      debugPrint('Error updating profile photo: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Refresh profile data
  Future<void> refreshProfile() async {
    setLoading(true);
    clearMessages();

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
        setSuccess('Profil berhasil diperbarui dari server');
      } else {
        final errorMessage = userProfileResponse?.message ??
            'Gagal memperbarui profil dari server';
        debugPrint('Error refreshing profile: $errorMessage');
        setError(errorMessage);
      }
    } on HttpException catch (e) {
      setError('Error HTTP: ${e.message}');
      debugPrint('HTTP error refreshing profile: $e');
    } catch (e) {
      setError('Terjadi kesalahan saat memperbarui profil: ${e.toString()}');
      debugPrint('Error refreshing profile: $e');
    } finally {
      setLoading(false);
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

  // Clear provider state (for debugging and reloading)
  void clearState() {
    _profile = null;
    _isInitialized = false;
    clearMessages();
    notifyListeners();
    debugPrint('ProfileProvider state cleared');
  }

  // DataSync bekerja otomatis, tidak perlu callback manual lagi
}
