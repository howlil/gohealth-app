import 'package:flutter/foundation.dart' show debugPrint;
import '../models/api_response_model.dart';
import '../models/activity_plan_model.dart';
import '../utils/api_endpoints.dart';
import '../utils/api_service.dart';

class ActivityPlanService {
  static final ActivityPlanService _instance = ActivityPlanService._internal();
  final ApiService _apiService = ApiService();

  factory ActivityPlanService() => _instance;
  ActivityPlanService._internal();

  /// Create activity plan
  Future<ApiResponse<ActivityPlan>?> createActivityPlan(
      CreateActivityPlanRequest request) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.activityPlans,
        body: request.toJson(),
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final ActivityPlan plan = ActivityPlan.fromJson(response['data']);
        debugPrint('ActivityPlanService: Activity plan created successfully');
        return ApiResponse<ActivityPlan>(
          success: true,
          message: response['message'] ?? 'Rencana aktivitas berhasil dibuat',
          data: plan,
        );
      } else {
        return ApiResponse<ActivityPlan>(
          success: false,
          message: response['message'] ?? 'Failed to create activity plan',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('ActivityPlanService: Error creating activity plan: $e');
      return ApiResponse<ActivityPlan>(
        success: false,
        message: 'Gagal membuat rencana aktivitas',
        data: null,
      );
    }
  }

  /// Get user activity plans
  Future<ApiResponse<List<ActivityPlan>>?> getActivityPlans(
      {bool? isActive}) async {
    try {
      final Map<String, String> queryParams = {};
      if (isActive != null) {
        queryParams['isActive'] = isActive.toString();
      }

      final response = await _apiService.get(
        ApiEndpoints.activityPlans,
        requiresAuth: true,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        final List<ActivityPlan> plans = data
            .map((item) => ActivityPlan.fromJson(item as Map<String, dynamic>))
            .toList();

        debugPrint(
            'ActivityPlanService: Loaded ${plans.length} activity plans');
        return ApiResponse<List<ActivityPlan>>(
          success: true,
          message: response['message'] ?? 'Activity plans loaded successfully',
          data: plans,
        );
      } else {
        return ApiResponse<List<ActivityPlan>>(
          success: false,
          message: response['message'] ?? 'Failed to load activity plans',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('ActivityPlanService: Error getting activity plans: $e');
      return ApiResponse<List<ActivityPlan>>(
        success: false,
        message: 'Gagal memuat rencana aktivitas',
        data: null,
      );
    }
  }

  /// Get weekly schedule
  Future<ApiResponse<WeeklySchedule>?> getWeeklySchedule({String? date}) async {
    try {
      final Map<String, String> queryParams = {};
      if (date != null) {
        queryParams['date'] = date;
      }

      final response = await _apiService.get(
        ApiEndpoints.activityPlansSchedule,
        requiresAuth: true,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response['success'] == true) {
        final WeeklySchedule schedule =
            WeeklySchedule.fromJson(response['data']);
        debugPrint('ActivityPlanService: Weekly schedule loaded');
        return ApiResponse<WeeklySchedule>(
          success: true,
          message: response['message'] ?? 'Weekly schedule loaded successfully',
          data: schedule,
        );
      } else {
        return ApiResponse<WeeklySchedule>(
          success: false,
          message: response['message'] ?? 'Failed to load weekly schedule',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('ActivityPlanService: Error getting weekly schedule: $e');
      return ApiResponse<WeeklySchedule>(
        success: false,
        message: 'Gagal memuat jadwal mingguan',
        data: null,
      );
    }
  }

  /// Get activity plan by ID
  Future<ApiResponse<ActivityPlan>?> getActivityPlanById(String planId) async {
    try {
      final response = await _apiService.get(
        '${ApiEndpoints.activityPlans}/$planId',
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final ActivityPlan plan = ActivityPlan.fromJson(response['data']);
        debugPrint('ActivityPlanService: Activity plan loaded');
        return ApiResponse<ActivityPlan>(
          success: true,
          message: response['message'] ?? 'Activity plan loaded successfully',
          data: plan,
        );
      } else {
        return ApiResponse<ActivityPlan>(
          success: false,
          message: response['message'] ?? 'Failed to load activity plan',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('ActivityPlanService: Error getting activity plan: $e');
      return ApiResponse<ActivityPlan>(
        success: false,
        message: 'Gagal memuat rencana aktivitas',
        data: null,
      );
    }
  }

  /// Update activity plan
  Future<ApiResponse<ActivityPlan>?> updateActivityPlan(
    String planId,
    CreateActivityPlanRequest request,
  ) async {
    try {
      final response = await _apiService.put(
        '${ApiEndpoints.activityPlans}/$planId',
        body: request.toJson(),
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final ActivityPlan plan = ActivityPlan.fromJson(response['data']);
        debugPrint('ActivityPlanService: Activity plan updated successfully');
        return ApiResponse<ActivityPlan>(
          success: true,
          message:
              response['message'] ?? 'Rencana aktivitas berhasil diperbarui',
          data: plan,
        );
      } else {
        return ApiResponse<ActivityPlan>(
          success: false,
          message: response['message'] ?? 'Failed to update activity plan',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('ActivityPlanService: Error updating activity plan: $e');
      return ApiResponse<ActivityPlan>(
        success: false,
        message: 'Gagal memperbarui rencana aktivitas',
        data: null,
      );
    }
  }

  /// Delete activity plan
  Future<ApiResponse<void>?> deleteActivityPlan(String planId) async {
    try {
      final response = await _apiService.delete(
        '${ApiEndpoints.activityPlans}/$planId',
        requiresAuth: true,
      );

      if (response['success'] == true) {
        debugPrint('ActivityPlanService: Activity plan deleted successfully');
        return ApiResponse<void>(
          success: true,
          message: response['message'] ?? 'Rencana aktivitas berhasil dihapus',
          data: null,
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response['message'] ?? 'Failed to delete activity plan',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('ActivityPlanService: Error deleting activity plan: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Gagal menghapus rencana aktivitas',
        data: null,
      );
    }
  }

  /// Activate activity plan
  Future<ApiResponse<ActivityPlan>?> activateActivityPlan(String planId) async {
    try {
      final response = await _apiService.patch(
        '${ApiEndpoints.activityPlans}/$planId/activate',
        body: {},
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final ActivityPlan plan = ActivityPlan.fromJson(response['data']);
        debugPrint('ActivityPlanService: Activity plan activated successfully');
        return ApiResponse<ActivityPlan>(
          success: true,
          message:
              response['message'] ?? 'Rencana aktivitas berhasil diaktifkan',
          data: plan,
        );
      } else {
        return ApiResponse<ActivityPlan>(
          success: false,
          message: response['message'] ?? 'Failed to activate activity plan',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('ActivityPlanService: Error activating activity plan: $e');
      return ApiResponse<ActivityPlan>(
        success: false,
        message: 'Gagal mengaktifkan rencana aktivitas',
        data: null,
      );
    }
  }

  /// Deactivate activity plan
  Future<ApiResponse<ActivityPlan>?> deactivateActivityPlan(
      String planId) async {
    try {
      final response = await _apiService.patch(
        '${ApiEndpoints.activityPlans}/$planId/deactivate',
        body: {},
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final ActivityPlan plan = ActivityPlan.fromJson(response['data']);
        debugPrint(
            'ActivityPlanService: Activity plan deactivated successfully');
        return ApiResponse<ActivityPlan>(
          success: true,
          message:
              response['message'] ?? 'Rencana aktivitas berhasil dinonaktifkan',
          data: plan,
        );
      } else {
        return ApiResponse<ActivityPlan>(
          success: false,
          message: response['message'] ?? 'Failed to deactivate activity plan',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('ActivityPlanService: Error deactivating activity plan: $e');
      return ApiResponse<ActivityPlan>(
        success: false,
        message: 'Gagal menonaktifkan rencana aktivitas',
        data: null,
      );
    }
  }

  /// Add planned activity to plan
  Future<ApiResponse<PlannedActivity>?> addPlannedActivity(
    String planId,
    CreatePlannedActivityRequest request,
  ) async {
    try {
      final response = await _apiService.post(
        '${ApiEndpoints.activityPlans}/$planId/activities',
        body: request.toJson(),
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final PlannedActivity activity =
            PlannedActivity.fromJson(response['data']);
        debugPrint('ActivityPlanService: Planned activity added successfully');
        return ApiResponse<PlannedActivity>(
          success: true,
          message: response['message'] ??
              'Aktivitas berhasil ditambahkan ke rencana',
          data: activity,
        );
      } else {
        return ApiResponse<PlannedActivity>(
          success: false,
          message: response['message'] ?? 'Failed to add planned activity',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('ActivityPlanService: Error adding planned activity: $e');
      return ApiResponse<PlannedActivity>(
        success: false,
        message: 'Gagal menambahkan aktivitas ke rencana',
        data: null,
      );
    }
  }

  /// Update planned activity in plan
  Future<ApiResponse<PlannedActivity>?> updatePlannedActivity(
    String planId,
    String activityTypeId,
    CreatePlannedActivityRequest request,
  ) async {
    try {
      final response = await _apiService.put(
        '${ApiEndpoints.activityPlans}/$planId/activities/$activityTypeId',
        body: request.toJson(),
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final PlannedActivity activity =
            PlannedActivity.fromJson(response['data']);
        debugPrint(
            'ActivityPlanService: Planned activity updated successfully');
        return ApiResponse<PlannedActivity>(
          success: true,
          message: response['message'] ?? 'Aktivitas berhasil diperbarui',
          data: activity,
        );
      } else {
        return ApiResponse<PlannedActivity>(
          success: false,
          message: response['message'] ?? 'Failed to update planned activity',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('ActivityPlanService: Error updating planned activity: $e');
      return ApiResponse<PlannedActivity>(
        success: false,
        message: 'Gagal memperbarui aktivitas',
        data: null,
      );
    }
  }

  /// Remove planned activity from plan
  Future<ApiResponse<void>?> removePlannedActivity(
    String planId,
    String activityTypeId,
  ) async {
    try {
      final response = await _apiService.delete(
        '${ApiEndpoints.activityPlans}/$planId/activities/$activityTypeId',
        requiresAuth: true,
      );

      if (response['success'] == true) {
        debugPrint(
            'ActivityPlanService: Planned activity removed successfully');
        return ApiResponse<void>(
          success: true,
          message:
              response['message'] ?? 'Aktivitas berhasil dihapus dari rencana',
          data: null,
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response['message'] ?? 'Failed to remove planned activity',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('ActivityPlanService: Error removing planned activity: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Gagal menghapus aktivitas dari rencana',
        data: null,
      );
    }
  }
}
