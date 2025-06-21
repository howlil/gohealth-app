import 'package:flutter/foundation.dart';
import '../dao/user_dao.dart';
import '../models/local_user_model.dart';
import '../models/user_profile_model.dart';
import '../services/user_service.dart';
import '../utils/storage_util.dart';

class LocalUserService {
  static final LocalUserService _instance = LocalUserService._internal();
  final UserDao _userDao = UserDao();
  final UserService _userService = UserService();

  factory LocalUserService() => _instance;
  LocalUserService._internal();

  // Save user data locally after login/registration
  Future<void> saveUserLocally({
    required String id,
    required String name,
    required String email,
    int? age,
    double? height,
    double? weight,
    String? profileImage,
    String? accessToken,
    String? refreshToken,
  }) async {
    try {
      final now = DateTime.now();

      // Create local user
      final localUser = LocalUser(
        id: id,
        name: name,
        email: email,
        age: age,
        height: height,
        weight: weight,
        profileImage: profileImage,
        createdAt: now,
        updatedAt: now,
        isSynced: true, // Mark as synced since it came from server
      );

      // Save user to local database
      await _userDao.saveUser(localUser);

      // Save session if tokens provided
      if (accessToken != null) {
        final session = LocalUserSession(
          userId: id,
          accessToken: accessToken,
          refreshToken: refreshToken,
          createdAt: now,
          isActive: true,
        );
        await _userDao.saveUserSession(session);
      }

      debugPrint('User data saved locally: $id');
    } catch (e) {
      debugPrint('Error saving user locally: $e');
      rethrow;
    }
  }

  // Get current user from local storage
  Future<LocalUser?> getCurrentUserLocal() async {
    try {
      return await _userDao.getCurrentUser();
    } catch (e) {
      debugPrint('Error getting current user locally: $e');
      return null;
    }
  }

  // Update user profile locally
  Future<bool> updateUserProfile({
    required String userId,
    String? name,
    int? age,
    double? height,
    double? weight,
    String? profileImage,
  }) async {
    try {
      final currentUser = await _userDao.getUserById(userId);
      if (currentUser == null) {
        debugPrint('User not found locally: $userId');
        return false;
      }

      final updatedUser = currentUser.copyWith(
        name: name ?? currentUser.name,
        age: age ?? currentUser.age,
        height: height ?? currentUser.height,
        weight: weight ?? currentUser.weight,
        profileImage: profileImage ?? currentUser.profileImage,
        updatedAt: DateTime.now(),
        isSynced: false, // Mark as not synced
      );

      final success = await _userDao.updateUser(updatedUser);

      if (success) {
        // Try to sync with server in background
        _syncUserWithServer(updatedUser);
      }

      return success;
    } catch (e) {
      debugPrint('Error updating user profile locally: $e');
      return false;
    }
  }

  // Sync local user data with server
  Future<void> _syncUserWithServer(LocalUser localUser) async {
    try {
      debugPrint('Syncing user with server: ${localUser.id}');

      // Convert to UserProfileData format for API
      final profileData = UserProfileData(
        id: localUser.id,
        name: localUser.name,
        email: localUser.email,
        age: localUser.age,
        height: localUser.height,
        weight: localUser.weight,
        profileImage: localUser.profileImage,
      );

      // Update profile on server
      final response = await _userService.updateProfile(profileData);

      if (response != null && response.success) {
        // Mark as synced
        await _userDao.markUserAsSynced(localUser.id);
        debugPrint('User synced successfully: ${localUser.id}');
      } else {
        debugPrint('Failed to sync user: ${response?.message}');
      }
    } catch (e) {
      debugPrint('Error syncing user with server: $e');
    }
  }

  // Sync all unsynced users with server
  Future<void> syncAllUnsyncedUsers() async {
    try {
      final unsyncedUsers = await _userDao.getUnsyncedUsers();
      debugPrint('Found ${unsyncedUsers.length} unsynced users');

      for (final user in unsyncedUsers) {
        await _syncUserWithServer(user);
        // Add delay to avoid overwhelming server
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      debugPrint('Error syncing unsynced users: $e');
    }
  }

  // Get user session info
  Future<LocalUserSession?> getCurrentSession() async {
    try {
      return await _userDao.getActiveSession();
    } catch (e) {
      debugPrint('Error getting current session: $e');
      return null;
    }
  }

  // Load user from server and update local cache
  Future<LocalUser?> loadUserFromServer() async {
    try {
      debugPrint('Loading user profile from server');

      final response = await _userService.getCurrentUser();
      if (response == null || !response.success || response.data == null) {
        debugPrint('Failed to load user from server');
        return null;
      }

      final profile = response.data!;

      // Get current user ID from storage or session
      final session = await getCurrentSession();
      if (session == null) {
        debugPrint('No active session found');
        return null;
      }

      // Create/update local user with server data
      final localUser = LocalUser(
        id: session.userId,
        name: profile.name ?? '',
        email: profile.email ?? '',
        age: profile.age,
        height: profile.height,
        weight: profile.weight,
        profileImage: profile.profileImage,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: true,
      );

      await _userDao.saveUser(localUser);
      debugPrint('User profile loaded and cached locally');

      return localUser;
    } catch (e) {
      debugPrint('Error loading user from server: $e');
      return null;
    }
  }

  // Get user profile (prioritize local, fallback to server)
  Future<LocalUser?> getUserProfile({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        // Try to get from local cache first
        final localUser = await getCurrentUserLocal();
        if (localUser != null) {
          debugPrint('User loaded from local cache');
          return localUser;
        }
      }

      // Load from server if not in cache or force refresh
      return await loadUserFromServer();
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  // Clear all local user data
  Future<void> clearAllLocalData() async {
    try {
      await _userDao.clearAllSessions();
      final users = await _userDao.getAllUsers();
      for (final user in users) {
        await _userDao.deleteUser(user.id);
      }
      debugPrint('All local user data cleared');
    } catch (e) {
      debugPrint('Error clearing local data: $e');
    }
  }

  // Logout user locally
  Future<void> logoutUser() async {
    try {
      await _userDao.clearAllSessions();
      await StorageUtil.clearAuthData();
      debugPrint('User logged out locally');
    } catch (e) {
      debugPrint('Error logging out user: $e');
    }
  }

  // Check if user is logged in locally
  Future<bool> isUserLoggedIn() async {
    try {
      final session = await getCurrentSession();
      if (session == null) return false;

      // Check if tokens exist in secure storage
      final accessToken = await StorageUtil.getAccessToken();
      return accessToken != null;
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return false;
    }
  }

  // Get user statistics for debugging
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final allUsers = await _userDao.getAllUsers();
      final unsyncedUsers = await _userDao.getUnsyncedUsers();
      final currentUser = await getCurrentUserLocal();
      final activeSession = await getCurrentSession();

      return {
        'totalUsers': allUsers.length,
        'unsyncedUsers': unsyncedUsers.length,
        'hasCurrentUser': currentUser != null,
        'hasActiveSession': activeSession != null,
        'currentUserId': currentUser?.id,
        'sessionUserId': activeSession?.userId,
      };
    } catch (e) {
      debugPrint('Error getting user statistics: $e');
      return {};
    }
  }

  // Convert LocalUser to UserProfileData for UI compatibility
  UserProfileData? localUserToProfileData(LocalUser? localUser) {
    if (localUser == null) return null;

    return UserProfileData(
      id: localUser.id,
      name: localUser.name,
      email: localUser.email,
      age: localUser.age,
      height: localUser.height,
      weight: localUser.weight,
      profileImage: localUser.profileImage,
    );
  }

  // Convert UserProfileData to LocalUser
  LocalUser profileDataToLocalUser(UserProfileData profile, String userId) {
    return LocalUser(
      id: userId,
      name: profile.name ?? '',
      email: profile.email ?? '',
      age: profile.age,
      height: profile.height,
      weight: profile.weight,
      profileImage: profile.profileImage,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: true,
    );
  }
}
