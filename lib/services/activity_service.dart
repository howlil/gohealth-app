import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/api_response_model.dart';
import '../utils/api_endpoints.dart';
import '../utils/app_constants.dart';
import '../utils/storage_util.dart';
import '../utils/api_service.dart';

class Activity {
  final String? id;
  final String name;
  final String type;
  final int duration; // in minutes
  final double caloriesBurned;
  final DateTime date;
  final DateTime? createdAt;

  Activity({
    this.id,
    required this.name,
    required this.type,
    required this.duration,
    required this.caloriesBurned,
    required this.date,
    this.createdAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String?,
      name: json['name'] as String,
      type: json['type'] as String,
      duration: json['duration'] as int,
      caloriesBurned: (json['caloriesBurned'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'duration': duration,
      'caloriesBurned': caloriesBurned,
      'date': date.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class ActivityService {
  static final ActivityService _instance = ActivityService._internal();
  final ApiService _apiService = ApiService();

  factory ActivityService() => _instance;
  ActivityService._internal();

  // Get user activities for a specific date
  Future<ApiResponse<List<Activity>>?> getActivities({String? date}) async {
    try {
      final response = await _apiService.get(
        '${ApiEndpoints.activities}${date != null ? '?date=$date' : ''}',
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        final List<Activity> activities = data
            .map((item) => Activity.fromJson(item as Map<String, dynamic>))
            .toList();

        return ApiResponse<List<Activity>>(
          success: true,
          message: response['message'] ?? 'Activities retrieved successfully',
          data: activities,
        );
      } else {
        return ApiResponse<List<Activity>>(
          success: false,
          message: response['message'] ?? 'Failed to get activities',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error getting activities: $e');
      return ApiResponse<List<Activity>>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  // Add activity
  Future<ApiResponse<Activity>?> addActivity({
    required String name,
    required String type,
    required int duration,
    required double caloriesBurned,
    String? date,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.activities,
        body: {
          'name': name,
          'type': type,
          'duration': duration,
          'caloriesBurned': caloriesBurned,
          'date': date ?? DateTime.now().toIso8601String().split('T')[0],
        },
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final activity = Activity.fromJson(response['data']);
        return ApiResponse<Activity>(
          success: true,
          message: response['message'] ?? 'Activity added successfully',
          data: activity,
        );
      } else {
        return ApiResponse<Activity>(
          success: false,
          message: response['message'] ?? 'Failed to add activity',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error adding activity: $e');
      return ApiResponse<Activity>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  // Delete activity
  Future<ApiResponse<String>?> deleteActivity(String activityId) async {
    try {
      final response = await _apiService.get(
        '${ApiEndpoints.activities}/$activityId',
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return ApiResponse<String>(
          success: true,
          message: response['message'] ?? 'Activity deleted successfully',
          data: 'Deleted',
        );
      } else {
        return ApiResponse<String>(
          success: false,
          message: response['message'] ?? 'Failed to delete activity',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error deleting activity: $e');
      return ApiResponse<String>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }
}
