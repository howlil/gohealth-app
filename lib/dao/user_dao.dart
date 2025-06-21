import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../models/local_user_model.dart';
import 'database_helper.dart';

class UserDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Insert or update user
  Future<void> saveUser(LocalUser user) async {
    final db = await _databaseHelper.database;

    try {
      await db.insert(
        'users',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('User saved locally: ${user.id}');
    } catch (e) {
      debugPrint('Error saving user: $e');
      rethrow;
    }
  }

  // Get user by ID
  Future<LocalUser?> getUserById(String userId) async {
    final db = await _databaseHelper.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return LocalUser.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user by ID: $e');
      return null;
    }
  }

  // Get user by email
  Future<LocalUser?> getUserByEmail(String email) async {
    final db = await _databaseHelper.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return LocalUser.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user by email: $e');
      return null;
    }
  }

  // Get current logged in user (assuming only one active session)
  Future<LocalUser?> getCurrentUser() async {
    final db = await _databaseHelper.database;

    try {
      // Get user from active session
      final sessionMaps = await db.query(
        'user_sessions',
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'created_at DESC',
        limit: 1,
      );

      if (sessionMaps.isNotEmpty) {
        final session = LocalUserSession.fromMap(sessionMaps.first);
        return await getUserById(session.userId);
      }

      // Fallback: get the most recently updated user
      final userMaps = await db.query(
        'users',
        orderBy: 'updated_at DESC',
        limit: 1,
      );

      if (userMaps.isNotEmpty) {
        return LocalUser.fromMap(userMaps.first);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUser(LocalUser user) async {
    final db = await _databaseHelper.database;

    try {
      final updatedUser = user.copyWith(
        updatedAt: DateTime.now(),
        isSynced: false, // Mark as not synced when updated locally
      );

      final rowsAffected = await db.update(
        'users',
        updatedUser.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );

      debugPrint('User updated: ${rowsAffected > 0}');
      return rowsAffected > 0;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }

  // Delete user
  Future<bool> deleteUser(String userId) async {
    final db = await _databaseHelper.database;

    try {
      await db.transaction((txn) async {
        // Delete user sessions first (foreign key constraint)
        await txn.delete(
          'user_sessions',
          where: 'user_id = ?',
          whereArgs: [userId],
        );

        // Delete user
        await txn.delete(
          'users',
          where: 'id = ?',
          whereArgs: [userId],
        );
      });

      debugPrint('User deleted: $userId');
      return true;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    }
  }

  // Get all users (for debugging or multi-user support)
  Future<List<LocalUser>> getAllUsers() async {
    final db = await _databaseHelper.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        orderBy: 'updated_at DESC',
      );

      return List.generate(maps.length, (i) {
        return LocalUser.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }

  // Mark user as synced
  Future<bool> markUserAsSynced(String userId) async {
    final db = await _databaseHelper.database;

    try {
      final rowsAffected = await db.update(
        'users',
        {'is_synced': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [userId],
      );

      return rowsAffected > 0;
    } catch (e) {
      debugPrint('Error marking user as synced: $e');
      return false;
    }
  }

  // Get unsynced users
  Future<List<LocalUser>> getUnsyncedUsers() async {
    final db = await _databaseHelper.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'is_synced = ?',
        whereArgs: [0],
        orderBy: 'updated_at DESC',
      );

      return List.generate(maps.length, (i) {
        return LocalUser.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Error getting unsynced users: $e');
      return [];
    }
  }

  // Save user session
  Future<void> saveUserSession(LocalUserSession session) async {
    final db = await _databaseHelper.database;

    try {
      // Deactivate all existing sessions for this user
      await db.update(
        'user_sessions',
        {'is_active': 0},
        where: 'user_id = ?',
        whereArgs: [session.userId],
      );

      // Insert new active session
      await db.insert(
        'user_sessions',
        session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint('User session saved: ${session.userId}');
    } catch (e) {
      debugPrint('Error saving user session: $e');
      rethrow;
    }
  }

  // Get active session
  Future<LocalUserSession?> getActiveSession() async {
    final db = await _databaseHelper.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'user_sessions',
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'created_at DESC',
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return LocalUserSession.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting active session: $e');
      return null;
    }
  }

  // Clear all user sessions
  Future<void> clearAllSessions() async {
    final db = await _databaseHelper.database;

    try {
      await db.update(
        'user_sessions',
        {'is_active': 0},
      );
      debugPrint('All user sessions cleared');
    } catch (e) {
      debugPrint('Error clearing sessions: $e');
    }
  }

  // Check if user exists locally
  Future<bool> userExists(String userId) async {
    final user = await getUserById(userId);
    return user != null;
  }
}
