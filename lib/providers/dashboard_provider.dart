import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../services/user_service.dart';
import '../services/data_sync_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'base_provider.dart';

class DashboardProvider extends BaseProvider {
  final UserService _userService = UserService();
  final DataSyncService _dataSyncService = DataSyncService();

  DashboardData? _dashboardData;
  String _timeRange = 'week'; // 'week' or 'month'
  DateTime _selectedDate =
      DateTime.now(); // Current selected date for dashboard
  bool _isOnline = true;

  // Getters
  DashboardData? get dashboardData => _dashboardData;
  String get timeRange => _timeRange;
  DateTime get selectedDate => _selectedDate;
  bool get isOnline => _isOnline;

  // Get formatted date for display
  String get selectedDateFormatted {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year}';
  }

  // Calories data for the chart
  List<FlSpot> get caloriesSpots {
    if (_dashboardData == null || _dashboardData!.caloriesTracker.isEmpty) {
      return [];
    }

    final trackingData = _dashboardData!.caloriesTracker;

    return List.generate(trackingData.length, (index) {
      return FlSpot(index.toDouble(), trackingData[index].calories);
    });
  }

  // User profile info
  String get userName => _dashboardData?.user.name ?? 'User';
  double get userWeight => _dashboardData?.user.weight ?? 0.0;
  double get userHeight => _dashboardData?.user.height ?? 0.0;
  double get userBmr => _dashboardData?.user.bmr ?? 0.0;
  double get userTdee => _dashboardData?.user.tdee ?? 0.0;

  // Calories info
  double get caloriesConsumed => _dashboardData?.calories.consumed ?? 0.0;
  double get caloriesBurned =>
      _dashboardData?.calories.burnedFromActivities ?? 0.0;
  double get caloriesBmr => _dashboardData?.calories.bmr ?? 0.0;
  double get caloriesTdee => _dashboardData?.calories.tdee ?? 0.0;
  double get caloriesNet => _dashboardData?.calories.net ?? 0.0;
  double get caloriesTarget => _dashboardData?.calories.target ?? 0.0;

  // Activities info
  int get activitiesCount => _dashboardData?.activities.count ?? 0;
  int get activitiesTotalDuration =>
      _dashboardData?.activities.totalDuration ?? 0;
  double get activitiesTotalCaloriesBurned =>
      _dashboardData?.activities.totalCaloriesBurned ?? 0.0;

  // Weight goal info
  double get weightGoalStartWeight =>
      _dashboardData?.weightGoal?.startWeight ?? 0.0;
  double get weightGoalTargetWeight =>
      _dashboardData?.weightGoal?.targetWeight ?? 0.0;
  String get weightGoalStartDate => _dashboardData?.weightGoal?.startDate ?? '';
  String get weightGoalTargetDate =>
      _dashboardData?.weightGoal?.targetDate ?? '';

  // BMI info
  double get bmiValue => _dashboardData?.latestBMI?.bmi ?? 0.0;
  String get bmiStatus => _dashboardData?.latestBMI?.status ?? 'UNKNOWN';

  // Nutrition summary
  NutritionSummary? get nutritionSummary =>
      _dashboardData?.latestBMI?.nutritionSummary;

  // Chart labels
  List<String> get chartLabels {
    if (_dashboardData == null || _dashboardData!.caloriesTracker.isEmpty) {
      return [];
    }

    final trackingData = _dashboardData!.caloriesTracker;
    return trackingData.map((item) => item.label).toList();
  }

  // Load dashboard data
  Future<void> loadDashboardData({String? date, String range = 'week'}) async {
    setLoading(true);
    clearMessages();
    _timeRange = range;

    // Use provided date or convert selected date to API format
    String apiDate;
    if (date != null) {
      apiDate = date;
    } else {
      // Convert selectedDate to DD-MM-YYYY format for API
      apiDate =
          '${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}';
    }

    debugPrint('🔄 Loading dashboard data with range: $range');
    debugPrint('🔄 Loading dashboard data for date: $apiDate');
    debugPrint('🔄 Selected date object: $_selectedDate');

    try {
      final response = await _userService.getDashboardData(
        date: apiDate,
        range: range,
      );

      debugPrint('🔄 Dashboard API Response Status: ${response?.success}');
      debugPrint('🔄 Dashboard API Response Message: ${response?.message}');

      if (response?.success == true && response?.data != null) {
        debugPrint('✅ Dashboard data received successfully');
        debugPrint('📊 Raw Dashboard Data: ${response!.data}');

        try {
          _dashboardData =
              DashboardData.fromJson(response.data as Map<String, dynamic>);

          // Debug: Print detailed chart data
          debugPrint(
              '📈 Chart labels received: ${_dashboardData!.caloriesTracker.map((e) => e.label).toList()}');
          debugPrint(
              '📈 Chart calories received: ${_dashboardData!.caloriesTracker.map((e) => e.calories).toList()}');
          debugPrint(
              '📈 Total entries: ${_dashboardData!.caloriesTracker.length}');

          // Debug: Print calories info
          debugPrint(
              '🔥 Calories consumed: ${_dashboardData!.calories.consumed}');
          debugPrint('🔥 Calories target: ${_dashboardData!.calories.target}');
          debugPrint('🔥 Calories BMR: ${_dashboardData!.calories.bmr}');
          debugPrint('🔥 Calories TDEE: ${_dashboardData!.calories.tdee}');

          // Debug: Print BMI and nutrition data
          debugPrint('⚖️ Latest BMI: ${_dashboardData!.latestBMI}');
          debugPrint(
              '🥗 Nutrition Summary: ${_dashboardData!.latestBMI?.nutritionSummary}');

          // Check if the received data matches the expected time range format
          bool dataMatchesTimeRange =
              _validateDataFormat(_dashboardData!.caloriesTracker);

          if (!dataMatchesTimeRange) {
            debugPrint(
                '⚠️ Data format does not match time range, using corrected chart data');
            // Keep the API data but fix the chart data only
            final originalData = _dashboardData!;
            _createFallbackDashboardData();

            // Restore the API data but with corrected chart
            _dashboardData = DashboardData(
              user: originalData.user,
              calories: originalData.calories,
              activities: originalData.activities,
              weightGoal: originalData.weightGoal,
              latestBMI: originalData.latestBMI,
              date: originalData.date,
              caloriesTracker:
                  _dashboardData!.caloriesTracker, // Use corrected chart data
            );

            debugPrint('✅ Combined data created with corrected chart labels');
            debugPrint(
                '📈 Final chart labels: ${_dashboardData!.caloriesTracker.map((e) => e.label).toList()}');
          }

          // Show success message
          setSuccess(response.message ?? 'Data dashboard berhasil dimuat');
        } catch (e) {
          debugPrint('❌ Error parsing dashboard data: $e');
          setError('Gagal memparse data dashboard: ${e.toString()}');
          _createFallbackDashboardData();
          return;
        }
      } else {
        final errorMessage = response?.message ?? 'Gagal memuat data dashboard';

        debugPrint('❌ Dashboard API failed: $errorMessage');
        debugPrint('🔄 Creating fallback data with range: $_timeRange');

        setError(errorMessage);
        // Create fallback dashboard data for better UX
        _createFallbackDashboardData();
      }
    } catch (e) {
      debugPrint('❌ Dashboard Error: $e');
      debugPrint('🔄 Creating fallback data due to exception');
      _createFallbackDashboardData();

      // Show appropriate error messages to user
      if (e.toString().contains('No internet') ||
          e.toString().contains('network')) {
        setError('Tidak ada koneksi internet. Menampilkan data offline.');
      } else {
        setError('Terjadi kesalahan saat memuat dashboard: ${e.toString()}');
      }
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// Public method to refresh dashboard data (called from meal screens)
  Future<void> refreshData() async {
    debugPrint('🔄 Manual refresh dashboard data requested');
    await loadDashboardData(range: _timeRange);
  }

  /// Force refresh with specific date (for meal updates)
  Future<void> refreshDataForDate(String date) async {
    debugPrint('🔄 Refresh dashboard data for specific date: $date');
    await loadDashboardData(date: date, range: _timeRange);
  }

  /// Change selected date for dashboard
  Future<void> changeDate(DateTime newDate) async {
    if (_selectedDate != newDate) {
      _selectedDate = newDate;
      debugPrint('📅 Dashboard date changed to: $_selectedDate');
      await loadDashboardData(range: _timeRange);
    }
  }

  /// Set date to today
  Future<void> setToday() async {
    await changeDate(DateTime.now());
  }

  /// Set specific date by string (DD-MM-YYYY format)
  Future<void> setDateFromString(String dateStr) async {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final newDate = DateTime(year, month, day);
        await changeDate(newDate);
      }
    } catch (e) {
      debugPrint('❌ Error parsing date string: $dateStr - $e');
      setError('Format tanggal tidak valid: $dateStr');
    }
  }

  // Create fallback dashboard data when API fails
  void _createFallbackDashboardData() {
    // Create sample chart data based on time range
    List<Map<String, dynamic>> chartData = [];

    if (_timeRange == 'week') {
      // For week filter, show daily data (7 days)
      chartData = [
        {'label': 'Sun', 'calories': 0.0},
        {'label': 'Mon', 'calories': 0.0},
        {'label': 'Tue', 'calories': 0.0},
        {'label': 'Wed', 'calories': 0.0},
        {'label': 'Thu', 'calories': 0.0},
        {'label': 'Fri', 'calories': 0.0},
        {'label': 'Sat', 'calories': 0.0},
      ];
    } else {
      // For month filter, show weekly data (5 weeks)
      chartData = [
        {'label': 'Week 1', 'calories': 0.0},
        {'label': 'Week 2', 'calories': 0.0},
        {'label': 'Week 3', 'calories': 0.0},
        {'label': 'Week 4', 'calories': 0.0},
        {'label': 'Week 5', 'calories': 0.0},
      ];
    }

    // Create basic fallback data so the UI doesn't break
    final fallbackData = {
      'user': {
        'name': 'User',
        'weight': 0.0,
        'height': 0.0,
        'bmr': 0.0,
        'tdee': 0.0,
      },
      'calories': {
        'consumed': 0.0,
        'burnedFromActivities': 0.0,
        'bmr': 0.0,
        'tdee': 0.0,
        'net': 0.0,
        'target': 0.0,
      },
      'activities': {
        'count': 0,
        'totalDuration': 0,
        'totalCaloriesBurned': 0.0,
      },
      'weightGoal': null, // No weight goal for new users
      'latestBMI':
          null, // No BMI data for new users - this ensures nutritionSummary is null
      'date': DateTime.now().toIso8601String(),
      'caloriesTracker': chartData,
    };

    debugPrint('Creating fallback data with latestBMI: null');
    _dashboardData = DashboardData.fromJson(fallbackData);
  }

  // Change time range
  void changeTimeRange(String range) {
    if (_timeRange != range) {
      _timeRange = range;
      loadDashboardData(range: range);
    }
  }

  // Validate if the data format matches the expected time range
  bool _validateDataFormat(List<CaloriesTrackerEntry> data) {
    if (data.isEmpty) {
      debugPrint('Validation: data is empty');
      return false;
    }

    // Get first label to check format
    final firstLabel = data.first.label.toLowerCase();
    debugPrint('Validation: timeRange=$_timeRange, firstLabel="$firstLabel"');

    if (_timeRange == 'week') {
      // For week mode, expect daily labels like "Sun", "Mon", etc
      // If we get week labels like "Week 1", use fallback
      const dayNames = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
      bool isValid = dayNames.any((day) => firstLabel.contains(day));
      debugPrint('Validation for week: $isValid (contains day name)');
      return isValid;
    } else {
      // For month mode, expect week labels like "Week 1", "Week 2", etc
      // If we get daily labels, use fallback
      bool isValid =
          firstLabel.contains('week') || firstLabel.contains('minggu');
      debugPrint('Validation for month: $isValid (contains week)');
      return isValid;
    }
  }
}
