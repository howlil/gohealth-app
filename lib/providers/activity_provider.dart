import 'package:flutter/foundation.dart';
import '../models/activity_model.dart' as model;
import '../models/api_response_model.dart';
import '../services/activity_service.dart';
import '../services/activity_plan_service.dart';
import '../models/activity_plan_model.dart';

class ActivityProvider extends ChangeNotifier {
  final ActivityService _activityService = ActivityService();
  final ActivityPlanService _activityPlanService = ActivityPlanService();

  // Loading states
  bool _isLoading = false;
  bool _isLoadingTypes = false;
  bool _isLoadingSummary = false;
  bool _isLoadingPlans = false;
  bool _isLoadingSchedule = false;

  // Error states
  String? _error;

  // Data states
  List<model.Activity> _activities = [];
  List<model.ActivityType> _activityTypes = [];
  model.DailyActivitySummary? _dailySummary;
  List<ActivityPlan> _activityPlans = [];
  WeeklySchedule? _weeklySchedule;

  // Current selected date for filtering
  String _selectedDate = _formatDateToDDMMYYYY(DateTime.now());

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingTypes => _isLoadingTypes;
  bool get isLoadingSummary => _isLoadingSummary;
  bool get isLoadingPlans => _isLoadingPlans;
  bool get isLoadingSchedule => _isLoadingSchedule;
  String? get error => _error;
  List<model.Activity> get activities => _activities;
  List<model.ActivityType> get activityTypes => _activityTypes;
  model.DailyActivitySummary? get dailySummary => _dailySummary;
  List<ActivityPlan> get activityPlans => _activityPlans;
  WeeklySchedule? get weeklySchedule => _weeklySchedule;
  String get selectedDate => _selectedDate;

  /// Initialize provider
  Future<void> initialize() async {
    debugPrint('ActivityProvider: Initializing...');
    await Future.wait([
      loadActivityTypes(),
      loadActivities(),
      loadDailySummary(),
      loadActivityPlans(),
      loadWeeklySchedule(),
    ]);
    debugPrint('ActivityProvider: Initialization complete');
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Load activity types
  Future<void> loadActivityTypes() async {
    _isLoadingTypes = true;
    _clearError();
    notifyListeners();

    try {
      final response = await _activityService.getActivityTypes();
      if (response != null && response.success) {
        _activityTypes = response.data ?? [];
        debugPrint(
            'ActivityProvider: Loaded ${_activityTypes.length} activity types');
      } else {
        _setError(response?.message ?? 'Gagal memuat jenis aktivitas');
      }
    } catch (e) {
      debugPrint('ActivityProvider: Error loading activity types: $e');
      _setError('Gagal memuat jenis aktivitas');
    } finally {
      _isLoadingTypes = false;
      notifyListeners();
    }
  }

  /// Load activities
  Future<void> loadActivities({String? startDate, String? endDate}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _activityService.getActivities(
        startDate: startDate,
        endDate: endDate,
        limit: 50,
      );

      if (response != null && response.success) {
        _activities = response.data ?? [];
        debugPrint('ActivityProvider: Loaded ${_activities.length} activities');
      } else {
        _setError(response?.message ?? 'Gagal memuat aktivitas');
      }
    } catch (e) {
      debugPrint('ActivityProvider: Error loading activities: $e');
      _setError('Gagal memuat aktivitas');
    } finally {
      _setLoading(false);
    }
  }

  /// Load daily activity summary
  Future<void> loadDailySummary({String? date}) async {
    _isLoadingSummary = true;
    _clearError();
    notifyListeners();

    final summaryDate = date ?? _selectedDate;

    try {
      final response =
          await _activityService.getDailyActivitySummary(summaryDate);
      if (response != null && response.success) {
        _dailySummary = response.data;
        debugPrint('ActivityProvider: Loaded daily summary for $summaryDate');
      } else {
        _setError(response?.message ?? 'Gagal memuat ringkasan aktivitas');
      }
    } catch (e) {
      debugPrint('ActivityProvider: Error loading daily summary: $e');
      _setError('Gagal memuat ringkasan aktivitas');
    } finally {
      _isLoadingSummary = false;
      notifyListeners();
    }
  }

  /// Load activity plans
  Future<void> loadActivityPlans({bool? isActive}) async {
    _isLoadingPlans = true;
    _clearError();
    notifyListeners();

    try {
      final response =
          await _activityPlanService.getActivityPlans(isActive: isActive);
      if (response != null && response.success) {
        _activityPlans = response.data ?? [];
        debugPrint(
            'ActivityProvider: Loaded ${_activityPlans.length} activity plans');
      } else {
        _setError(response?.message ?? 'Gagal memuat rencana aktivitas');
      }
    } catch (e) {
      debugPrint('ActivityProvider: Error loading activity plans: $e');
      _setError('Gagal memuat rencana aktivitas');
    } finally {
      _isLoadingPlans = false;
      notifyListeners();
    }
  }

  /// Load weekly schedule
  Future<void> loadWeeklySchedule({String? date}) async {
    _isLoadingSchedule = true;
    _clearError();
    notifyListeners();

    try {
      final response = await _activityPlanService.getWeeklySchedule(date: date);
      if (response != null && response.success) {
        _weeklySchedule = response.data;
        debugPrint('ActivityProvider: Loaded weekly schedule');
      } else {
        _setError(response?.message ?? 'Gagal memuat jadwal mingguan');
      }
    } catch (e) {
      debugPrint('ActivityProvider: Error loading weekly schedule: $e');
      _setError('Gagal memuat jadwal mingguan');
    } finally {
      _isLoadingSchedule = false;
      notifyListeners();
    }
  }

  /// Create activity
  Future<bool> createActivity(model.CreateActivityRequest request) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _activityService.createActivity(request);
      if (response != null && response.success) {
        await loadActivities(); // Refresh activities
        await loadDailySummary(); // Refresh summary
        return true;
      } else {
        final errorMessage = response?.message ?? 'Gagal menambahkan aktivitas';
        _setError(errorMessage);
        return false;
      }
    } catch (e) {
      debugPrint('ActivityProvider: Error creating activity: $e');
      final errorMessage = 'Gagal menambahkan aktivitas';
      _setError(errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update activity
  Future<bool> updateActivity(
      String activityTypeId, model.CreateActivityRequest request) async {
    _setLoading(true);
    _clearError();

    try {
      final response =
          await _activityService.updateActivity(activityTypeId, request);
      if (response != null && response.success) {
        await loadActivities(); // Refresh activities
        await loadDailySummary(); // Refresh summary
        return true;
      } else {
        final errorMessage = response?.message ?? 'Gagal memperbarui aktivitas';
        _setError(errorMessage);
        return false;
      }
    } catch (e) {
      debugPrint('ActivityProvider: Error updating activity: $e');
      final errorMessage = 'Gagal memperbarui aktivitas';
      _setError(errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete activity
  Future<bool> deleteActivity(String activityTypeId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _activityService.deleteActivity(activityTypeId);
      if (response != null && response.success) {
        await loadActivities(); // Refresh activities
        await loadDailySummary(); // Refresh summary
        return true;
      } else {
        final errorMessage = response?.message ?? 'Gagal menghapus aktivitas';
        _setError(errorMessage);
        return false;
      }
    } catch (e) {
      debugPrint('ActivityProvider: Error deleting activity: $e');
      final errorMessage = 'Gagal menghapus aktivitas';
      _setError(errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Create activity plan
  Future<bool> createActivityPlan(CreateActivityPlanRequest request) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _activityPlanService.createActivityPlan(request);
      if (response != null && response.success) {
        await loadActivityPlans(); // Refresh plans
        await loadWeeklySchedule(); // Refresh schedule
        return true;
      } else {
        final errorMessage =
            response?.message ?? 'Gagal membuat rencana aktivitas';
        _setError(errorMessage);
        return false;
      }
    } catch (e) {
      debugPrint('ActivityProvider: Error creating activity plan: $e');
      final errorMessage = 'Gagal membuat rencana aktivitas';
      _setError(errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update activity plan
  Future<bool> updateActivityPlan(
    String planId,
    CreateActivityPlanRequest request,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      final response =
          await _activityPlanService.updateActivityPlan(planId, request);
      if (response != null && response.success) {
        await loadActivityPlans(); // Refresh plans
        await loadWeeklySchedule(); // Refresh schedule
        return true;
      } else {
        final errorMessage =
            response?.message ?? 'Gagal memperbarui rencana aktivitas';
        _setError(errorMessage);
        return false;
      }
    } catch (e) {
      debugPrint('ActivityProvider: Error updating activity plan: $e');
      final errorMessage = 'Gagal memperbarui rencana aktivitas';
      _setError(errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete activity plan
  Future<bool> deleteActivityPlan(String planId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _activityPlanService.deleteActivityPlan(planId);
      if (response != null && response.success) {
        await loadActivityPlans(); // Refresh plans
        await loadWeeklySchedule(); // Refresh schedule
        return true;
      } else {
        final errorMessage =
            response?.message ?? 'Gagal menghapus rencana aktivitas';
        _setError(errorMessage);
        return false;
      }
    } catch (e) {
      debugPrint('ActivityProvider: Error deleting activity plan: $e');
      final errorMessage = 'Gagal menghapus rencana aktivitas';
      _setError(errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Activate activity plan
  Future<bool> activateActivityPlan(String planId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _activityPlanService.activateActivityPlan(planId);
      if (response != null && response.success) {
        await loadActivityPlans(); // Refresh plans
        await loadWeeklySchedule(); // Refresh schedule
        return true;
      } else {
        final errorMessage =
            response?.message ?? 'Gagal mengaktifkan rencana aktivitas';
        _setError(errorMessage);
        return false;
      }
    } catch (e) {
      debugPrint('ActivityProvider: Error activating activity plan: $e');
      final errorMessage = 'Gagal mengaktifkan rencana aktivitas';
      _setError(errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Deactivate activity plan
  Future<bool> deactivateActivityPlan(String planId) async {
    _setLoading(true);
    _clearError();

    try {
      final response =
          await _activityPlanService.deactivateActivityPlan(planId);
      if (response != null && response.success) {
        await loadActivityPlans(); // Refresh plans
        await loadWeeklySchedule(); // Refresh schedule
        return true;
      } else {
        final errorMessage =
            response?.message ?? 'Gagal menonaktifkan rencana aktivitas';
        _setError(errorMessage);
        return false;
      }
    } catch (e) {
      debugPrint('ActivityProvider: Error deactivating activity plan: $e');
      final errorMessage = 'Gagal menonaktifkan rencana aktivitas';
      _setError(errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get activity count by category for selected date
  Map<String, int> getActivityCountByCategory() {
    final todayActivities = getActivitiesForDate(_selectedDate);
    final counts = <String, int>{};

    for (final activity in todayActivities) {
      final category = activity.activityType.category;
      counts[category] = (counts[category] ?? 0) + 1;
    }

    return counts;
  }

  /// Get the next scheduled activity
  ScheduledActivity? get nextScheduledActivity {
    if (_weeklySchedule == null) return null;

    final now = DateTime.now();
    final currentDayOfWeek = now.weekday % 7; // Convert to 0=Sunday format
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Get today's remaining activities
    final todayActivities = (_weeklySchedule!
                .weeklySchedule[currentDayOfWeek] ??
            [])
        .where((activity) => activity.scheduledTime.compareTo(currentTime) > 0)
        .toList();

    if (todayActivities.isNotEmpty) {
      // Sort by time and return the earliest
      todayActivities
          .sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      return todayActivities.first;
    }

    // Look for next day's activities
    for (int i = 1; i < 7; i++) {
      final checkDay = (currentDayOfWeek + i) % 7;
      final dayActivities = _weeklySchedule!.weeklySchedule[checkDay] ?? [];
      if (dayActivities.isNotEmpty) {
        dayActivities
            .sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
        return dayActivities.first;
      }
    }

    return null;
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    debugPrint('ActivityProvider: Refreshing all data...');
    await Future.wait([
      loadActivityTypes(),
      loadActivities(),
      loadDailySummary(),
      loadActivityPlans(),
      loadWeeklySchedule(),
    ]);
    debugPrint('ActivityProvider: All data refreshed');
  }

  /// Update selected date and refresh data
  Future<void> updateSelectedDate(String date) async {
    _selectedDate = date;
    notifyListeners();
    await Future.wait([
      loadActivities(),
      loadDailySummary(date: date),
    ]);
  }

  /// Helper method to format date to DD-MM-YYYY
  static String _formatDateToDDMMYYYY(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  /// Get activities for specific date
  List<model.Activity> getActivitiesForDate(String date) {
    return _activities.where((activity) => activity.date == date).toList();
  }

  /// Get activity types by category
  List<model.ActivityType> getActivityTypesByCategory(String category) {
    return _activityTypes.where((type) => type.category == category).toList();
  }

  /// Get active activity plans
  List<ActivityPlan> get activeActivityPlans {
    return _activityPlans.where((plan) => plan.isActive).toList();
  }

  @override
  void dispose() {
    debugPrint('ActivityProvider: Disposing...');
    super.dispose();
  }
}
