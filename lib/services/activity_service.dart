import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/api_response_model.dart';
import '../utils/env_config.dart';
import '../api/endpoints.dart';
import '../utils/app_constants.dart';
import '../utils/storage_util.dart';

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
  factory ActivityService() => _instance;
  ActivityService._internal();

  // Get authentication headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await StorageUtil.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  // Get user activities for a specific date
  Future<ApiResponse<List<Activity>>?> getActivities({String? date}) async {
    try {
      final headers = await _getHeaders();
      String url = '${EnvConfig.apiBaseUrl}${ApiEndpoints.activities}';
      if (date != null) {
        url += '?date=$date';
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> activitiesList = data['data'] as List;
        final List<Activity> activities =
            activitiesList.map((item) => Activity.fromJson(item)).toList();

        return ApiResponse<List<Activity>>(
          success: true,
          message: data['message'] ?? 'Activities retrieved successfully',
          data: activities,
        );
      } else if (response.statusCode == 401) {
        debugPrint('Token expired, need to refresh');
        return null;
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<List<Activity>>(
          success: false,
          message: errorData['message'] ?? 'Failed to get activities',
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
      final headers = await _getHeaders();
      final body = json.encode({
        'name': name,
        'type': type,
        'duration': duration,
        'caloriesBurned': caloriesBurned,
        'date': date ?? DateTime.now().toIso8601String().split('T')[0],
      });

      final response = await http
          .post(
            Uri.parse('${EnvConfig.apiBaseUrl}${ApiEndpoints.activities}'),
            headers: headers,
            body: body,
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final activity = Activity.fromJson(data['data']);
        return ApiResponse<Activity>(
          success: true,
          message: data['message'] ?? 'Activity added successfully',
          data: activity,
        );
      } else if (response.statusCode == 401) {
        debugPrint('Token expired, need to refresh');
        return null;
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<Activity>(
          success: false,
          message: errorData['message'] ?? 'Failed to add activity',
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
      final headers = await _getHeaders();

      final response = await http
          .delete(
            Uri.parse(
                '${EnvConfig.apiBaseUrl}${ApiEndpoints.activities}/$activityId'),
            headers: headers,
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse<String>(
          success: true,
          message: data['message'] ?? 'Activity deleted successfully',
          data: 'Deleted',
        );
      } else if (response.statusCode == 401) {
        debugPrint('Token expired, need to refresh');
        return null;
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<String>(
          success: false,
          message: errorData['message'] ?? 'Failed to delete activity',
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
