import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../dao/user_dao.dart';
import '../models/local_user_model.dart';
import '../models/user_profile_model.dart';
import '../services/user_service.dart';
import '../utils/storage_util.dart';

class DataSyncService {
  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;
  DataSyncService._internal();

  final UserDao _userDao = UserDao();
  final UserService _userService = UserService();
  final Connectivity _connectivity = Connectivity();

  bool _isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicSyncTimer;

  // Minimal callbacks - hanya untuk internal logging
  final List<Function(bool isOnline)> _connectivityCallbacks = [];
  final List<Function(String userId, bool synced)> _syncStatusCallbacks = [];

  /// Initialize sync service
  Future<void> initialize() async {
    debugPrint('🔄 Initializing DataSyncService...');

    // Start monitoring connectivity
    _startConnectivityMonitoring();

    // Start periodic sync
    _startPeriodicSync();

    // Sync unsynced data immediately
    _syncInBackground();

    debugPrint('✅ DataSyncService initialized');
  }

  /// Dispose sync service
  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
    _connectivityCallbacks.clear();
    _syncStatusCallbacks.clear();
  }

  /// Check if device has internet connection
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none)) {
        return false;
      }

      // Additional check with actual network request
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Internet check failed: $e');
      return false;
    }
  }

  /// Sync user data between local database and SharedPreferences
  Future<void> syncUserDataSources(LocalUser localUser) async {
    try {
      debugPrint('🔄 Syncing user data sources for: ${localUser.id}');

      // Update SharedPreferences with latest local data
      await StorageUtil.setUserData({
        'id': localUser.id,
        'name': localUser.name,
        'email': localUser.email,
        'profileImage': localUser.profileImage,
        'age': localUser.age,
        'height': localUser.height,
        'weight': localUser.weight,
      });

      debugPrint('✅ User data sources synced successfully');
    } catch (e) {
      debugPrint('❌ Error syncing user data sources: $e');
    }
  }

  /// Update user data in both storage systems
  Future<bool> updateUserData({
    required String userId,
    String? name,
    int? age,
    double? height,
    double? weight,
    String? profileImage,
    bool syncToServer = true,
  }) async {
    try {
      debugPrint('🔄 Updating user data for: $userId');

      // Get current user from local database
      final currentUser = await _userDao.getUserById(userId);
      if (currentUser == null) {
        debugPrint('❌ User not found in local database: $userId');
        return false;
      }

      // Check if there are actual changes
      bool hasChanges = false;
      if (name != null && name != currentUser.name) hasChanges = true;
      if (age != null && age != currentUser.age) hasChanges = true;
      if (height != null && height != currentUser.height) hasChanges = true;
      if (weight != null && weight != currentUser.weight) hasChanges = true;
      if (profileImage != null && profileImage != currentUser.profileImage)
        hasChanges = true;

      if (!hasChanges) {
        debugPrint('ℹ️ No changes detected for user: $userId');
        return true; // No changes, but not an error
      }

      // Create updated user
      final updatedUser = currentUser.copyWith(
        name: name ?? currentUser.name,
        age: age ?? currentUser.age,
        height: height ?? currentUser.height,
        weight: weight ?? currentUser.weight,
        profileImage: profileImage ?? currentUser.profileImage,
        updatedAt: DateTime.now(),
        isSynced: false, // Mark as not synced only if there are changes
      );

      // Validate data before saving
      if (updatedUser.name.isEmpty || updatedUser.email.isEmpty) {
        debugPrint('❌ Invalid user data - name or email is empty');
        return false;
      }

      // Update local database
      final localSuccess = await _userDao.updateUser(updatedUser);
      if (!localSuccess) {
        debugPrint('❌ Failed to update user in local database');
        return false;
      }

      // Sync with SharedPreferences
      await syncUserDataSources(updatedUser);

      // Sync with server aggressively if requested and online
      if (syncToServer && await hasInternetConnection()) {
        // Try immediate sync
        _syncUserWithServer(updatedUser).then((success) {
          if (!success) {
            debugPrint('⚠️ Immediate sync failed, will retry automatically');
            // Auto-retry will happen through periodic sync
          }
        });
      }

      // Notify callbacks
      _notifySyncStatus(userId, updatedUser.isSynced);

      debugPrint('✅ User data updated successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating user data: $e');
      return false;
    }
  }

  /// Get current user with automatic fallback
  Future<LocalUser?> getCurrentUser() async {
    try {
      // First try from local database
      LocalUser? user = await _userDao.getCurrentUser();

      if (user != null) {
        // Ensure SharedPreferences is synced
        await syncUserDataSources(user);
        return user;
      }

      // Fallback: try to get from SharedPreferences and save to database
      final userData = await StorageUtil.getUserData();
      if (userData != null) {
        final session = await _userDao.getActiveSession();
        if (session != null) {
          user = LocalUser(
            id: session.userId,
            name: userData['name'] ?? '',
            email: userData['email'] ?? '',
            age: userData['age'] as int?,
            height: userData['height'] as double?,
            weight: userData['weight'] as double?,
            profileImage: userData['profileImage'] as String?,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isSynced: true,
          );

          await _userDao.saveUser(user);
          return user;
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting current user: $e');
      return null;
    }
  }

  /// Load user from server and update all local storage
  Future<LocalUser?> loadUserFromServer({bool forceRefresh = false}) async {
    if (!await hasInternetConnection()) {
      debugPrint('⚠️ No internet connection for server load');
      return await getCurrentUser(); // Return cached data
    }

    try {
      debugPrint('🔄 Loading user from server...');

      final response = await _userService.getCurrentUser();
      if (response?.success != true || response?.data == null) {
        debugPrint('❌ Failed to load user from server');
        return await getCurrentUser(); // Return cached data
      }

      final profile = response!.data!;
      final session = await _userDao.getActiveSession();

      if (session == null) {
        debugPrint('❌ No active session found');
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

      // Update local database
      await _userDao.saveUser(localUser);

      // Update SharedPreferences
      await syncUserDataSources(localUser);

      debugPrint('✅ User loaded from server and synced locally');
      return localUser;
    } catch (e) {
      debugPrint('❌ Error loading user from server: $e');
      return await getCurrentUser(); // Return cached data
    }
  }

  /// Sync unsynced users with server
  Future<void> syncUnsyncedUsers() async {
    if (_isSyncing || !await hasInternetConnection()) {
      debugPrint('⚠️ Skipping sync - already syncing or no internet');
      return;
    }

    _isSyncing = true;

    try {
      debugPrint('🔄 Syncing unsynced users...');

      final unsyncedUsers = await _userDao.getUnsyncedUsers();
      debugPrint('📊 Found ${unsyncedUsers.length} unsynced users');

      if (unsyncedUsers.isEmpty) {
        debugPrint('✅ No users to sync');
        return;
      }

      for (final user in unsyncedUsers) {
        // Only sync if user has meaningful data
        if (user.name.isNotEmpty && user.email.isNotEmpty) {
          await _syncUserWithServer(user);
        } else {
          debugPrint(
              '⚠️ Skipping sync for user with incomplete data: ${user.id}');
        }
        // Add delay to avoid overwhelming server
        await Future.delayed(const Duration(milliseconds: 500));
      }

      debugPrint('✅ Sync completed');
    } catch (e) {
      debugPrint('❌ Error syncing unsynced users: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync specific user with server (with retry)
  Future<bool> _syncUserWithServer(LocalUser localUser,
      {int retryCount = 0}) async {
    const maxRetries = 3;

    try {
      debugPrint(
          '🔄 Syncing user with server: ${localUser.id} (attempt ${retryCount + 1})');

      if (!await hasInternetConnection()) {
        debugPrint('⚠️ No internet connection for sync');
        return false;
      }

      // Get current profile from server first to preserve existing fields
      final currentProfileResponse = await _userService.getCurrentUser();

      UserProfileData profileData;
      if (currentProfileResponse?.success == true &&
          currentProfileResponse?.data != null) {
        // Update existing profile with only the fields we have in LocalUser
        final existingProfile = currentProfileResponse!.data!;
        profileData = existingProfile.copyWith(
          name: localUser.name.isNotEmpty ? localUser.name : null,
          age: localUser.age,
          height: localUser.height,
          weight: localUser.weight,
          profileImage: localUser.profileImage,
        );
      } else {
        // Create new profile with only LocalUser fields
        profileData = UserProfileData(
          id: localUser.id,
          name: localUser.name,
          email: localUser.email,
          age: localUser.age,
          height: localUser.height,
          weight: localUser.weight,
          profileImage: localUser.profileImage,
          // Don't set gender and activityLevel - let them remain null/empty
        );
      }

      debugPrint('Syncing profile data: ${profileData.toJson()}');

      // Update profile on server
      final response = await _userService.updateProfile(profileData);

      if (response?.success == true) {
        // Mark as synced
        await _userDao.markUserAsSynced(localUser.id);

        // Update SharedPreferences
        final syncedUser = localUser.copyWith(isSynced: true);
        await syncUserDataSources(syncedUser);

        // Notify callbacks
        _notifySyncStatus(localUser.id, true);

        debugPrint('✅ User synced successfully: ${localUser.id}');
        return true;
      } else {
        throw Exception('Server sync failed: ${response?.message}');
      }
    } catch (e) {
      debugPrint('❌ Error syncing user (attempt ${retryCount + 1}): $e');

      // Retry logic
      if (retryCount < maxRetries - 1) {
        final delay =
            Duration(seconds: (retryCount + 1) * 2); // Exponential backoff
        debugPrint('⏳ Retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);
        return await _syncUserWithServer(localUser, retryCount: retryCount + 1);
      }

      debugPrint('❌ Max retries reached for user: ${localUser.id}');
      return false;
    }
  }

  /// Start monitoring connectivity changes
  void _startConnectivityMonitoring() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = !results.contains(ConnectivityResult.none);
      debugPrint('📡 Connectivity changed: ${isOnline ? 'Online' : 'Offline'}');

      // Notify callbacks
      for (final callback in _connectivityCallbacks) {
        callback(isOnline);
      }

      // Sync when back online
      if (isOnline) {
        _syncInBackground();
      }
    });
  }

  /// Start periodic sync
  void _startPeriodicSync() {
    // Sync every 5 minutes instead of 2 minutes to be less aggressive
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      debugPrint('⏰ Periodic sync triggered automatically');
      _syncInBackground();
    });
  }

  /// Background sync (non-blocking) - improved to be less aggressive
  void _syncInBackground() {
    // Only sync if not already syncing and has unsynced data
    if (_isSyncing) {
      debugPrint('⚠️ Sync already in progress, skipping background sync');
      return;
    }

    // Sync immediately when data changes or connectivity is restored
    syncUnsyncedUsers().catchError((error) {
      debugPrint('❌ Background sync error: $error');
      // Retry after 2 minutes if sync fails, less aggressive than before
      Future.delayed(const Duration(minutes: 2), () {
        if (!_isSyncing) {
          _syncInBackground();
        }
      });
    });
  }

  /// Register connectivity callback
  void addConnectivityCallback(Function(bool isOnline) callback) {
    _connectivityCallbacks.add(callback);
  }

  /// Register sync status callback
  void addSyncStatusCallback(Function(String userId, bool synced) callback) {
    _syncStatusCallbacks.add(callback);
  }

  /// Remove connectivity callback
  void removeConnectivityCallback(Function(bool isOnline) callback) {
    _connectivityCallbacks.remove(callback);
  }

  /// Remove sync status callback
  void removeSyncStatusCallback(Function(String userId, bool synced) callback) {
    _syncStatusCallbacks.remove(callback);
  }

  /// Notify sync status callbacks
  void _notifySyncStatus(String userId, bool synced) {
    for (final callback in _syncStatusCallbacks) {
      callback(userId, synced);
    }
  }

  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStatistics() async {
    try {
      final allUsers = await _userDao.getAllUsers();
      final unsyncedUsers = await _userDao.getUnsyncedUsers();
      final hasConnection = await hasInternetConnection();

      return {
        'totalUsers': allUsers.length,
        'unsyncedUsers': unsyncedUsers.length,
        'hasConnection': hasConnection,
        'isSyncing': _isSyncing,
        'lastSync': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error getting sync statistics: $e');
      return {};
    }
  }

  /// Manual force sync
  Future<bool> forceSyncUser(String userId) async {
    try {
      final user = await _userDao.getUserById(userId);
      if (user == null) {
        debugPrint('❌ User not found for force sync: $userId');
        return false;
      }

      return await _syncUserWithServer(user);
    } catch (e) {
      debugPrint('❌ Error force syncing user: $e');
      return false;
    }
  }
}
