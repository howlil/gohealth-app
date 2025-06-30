import 'package:flutter/foundation.dart' show debugPrint;
import '../models/api_response_model.dart';
import '../models/activity_model.dart';
import '../utils/api_endpoints.dart';
import '../utils/api_service.dart';

class ActivityService {
  static final ActivityService _instance = ActivityService._internal();
  final ApiService _apiService = ApiService();

  factory ActivityService() => _instance;
  ActivityService._internal();

  /// Get activity types from server
  Future<ApiResponse<List<ActivityType>>?> getActivityTypes() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.activityTypes,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        final List<ActivityType> activityTypes = data
            .map((item) => ActivityType.fromJson(item as Map<String, dynamic>))
            .toList();

        debugPrint(
            'ActivityService: Loaded ${activityTypes.length} activity types');
        return ApiResponse<List<ActivityType>>(
          success: true,
          message: response['message'] ?? 'Activity types loaded successfully',
          data: activityTypes,
        );
      } else {
        return ApiResponse<List<ActivityType>>(
          success: false,
          message: response['message'] ?? 'Failed to load activity types',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('ActivityService: Error getting activity types: $e');
      return ApiResponse<List<ActivityType>>(
        success: false,
        message: 'Gagal memuat jenis aktivitas',
        data: null,
      );
    }
  }

  /// Create new activity
  Future<ApiResponse<Activity>?> createActivity(
      CreateActivityRequest request) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.activities,
        body: request.toJson(),
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final Activity activity = Activity.fromJson(response['data']);
        debugPrint('ActivityService: Activity created successfully');
        return ApiResponse<Activity>(
          success: true,
          message: response['message'] ?? 'Aktivitas berhasil ditambahkan',
          data: activity,
        );
      } else {
        return ApiResponse<Activity>(
          success: false,
          message: response['message'] ?? 'Failed to create activity',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('ActivityService: Error creating activity: $e');
      return ApiResponse<Activity>(
        success: false,
        message: 'Gagal menambahkan aktivitas',
        data: null,
      );
    }
  }

  /// Get user activities with optional filters
  Future<ApiResponse<List<Activity>>?> getActivities({
    String? startDate,
    String? endDate,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final response = await _apiService.get(
        ApiEndpoints.activities,
        requiresAuth: true,
        queryParams: queryParams,
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        final List<Activity> activities = data
            .map((item) => Activity.fromJson(item as Map<String, dynamic>))
            .toList();

        debugPrint('ActivityService: Loaded ${activities.length} activities');
        return ApiResponse<List<Activity>>(
          success: true,
          message: response['message'] ?? 'Activities loaded successfully',
          data: activities,
        );
      } else {
        return ApiResponse<List<Activity>>(
          success: false,
          message: response['message'] ?? 'Failed to load activities',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('ActivityService: Error getting activities: $e');
      return ApiResponse<List<Activity>>(
        success: false,
        message: 'Gagal memuat aktivitas',
        data: null,
      );
    }
  }

  /// Get daily activity summary
  Future<ApiResponse<DailyActivitySummary>?> getDailyActivitySummary(
      String date) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.activitySummary,
        requiresAuth: true,
        queryParams: {'date': date},
      );

      if (response['success'] == true) {
        final DailyActivitySummary summary =
            DailyActivitySummary.fromJson(response['data']);
        debugPrint('ActivityService: Daily activity summary loaded for $date');
        return ApiResponse<DailyActivitySummary>(
          success: true,
          message: response['message'] ??
              'Daily activity summary loaded successfully',
          data: summary,
        );
      } else {
        return ApiResponse<DailyActivitySummary>(
          success: false,
          message:
              response['message'] ?? 'Failed to load daily activity summary',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('ActivityService: Error getting daily activity summary: $e');
      return ApiResponse<DailyActivitySummary>(
        success: false,
        message: 'Gagal memuat ringkasan aktivitas harian',
        data: null,
      );
    }
  }

  /// Update activity
  Future<ApiResponse<Activity>?> updateActivity(
    String activityTypeId,
    CreateActivityRequest request,
  ) async {
    try {
      final response = await _apiService.put(
        '${ApiEndpoints.activities}/$activityTypeId',
        body: request.toJson(),
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final Activity activity = Activity.fromJson(response['data']);
        debugPrint('ActivityService: Activity updated successfully');
        return ApiResponse<Activity>(
          success: true,
          message: response['message'] ?? 'Aktivitas berhasil diperbarui',
          data: activity,
        );
      } else {
        return ApiResponse<Activity>(
          success: false,
          message: response['message'] ?? 'Failed to update activity',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('ActivityService: Error updating activity: $e');
      return ApiResponse<Activity>(
        success: false,
        message: 'Gagal memperbarui aktivitas',
        data: null,
      );
    }
  }

  /// Delete activity
  Future<ApiResponse<void>?> deleteActivity(String activityTypeId) async {
    try {
      final response = await _apiService.delete(
        '${ApiEndpoints.activities}/$activityTypeId',
        requiresAuth: true,
      );

      if (response['success'] == true) {
        debugPrint('ActivityService: Activity deleted successfully');
        return ApiResponse<void>(
          success: true,
          message: response['message'] ?? 'Aktivitas berhasil dihapus',
          data: null,
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response['message'] ?? 'Failed to delete activity',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('ActivityService: Error deleting activity: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Gagal menghapus aktivitas',
        data: null,
      );
    }
  }
}
