import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../utils/http_exception.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _dashboardData;
  String _timeRange = 'week'; // 'week' or 'month'

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get dashboardData => _dashboardData;
  String get timeRange => _timeRange;

  // Calories data for the chart
  List<FlSpot> get caloriesSpots {
    if (_dashboardData == null || 
        _dashboardData!['caloriesTracker'] == null) {
      return [];
    }

    final List<dynamic> trackingData = _dashboardData!['caloriesTracker'];
    
    if (_timeRange == 'week') {
      return List.generate(trackingData.length, (index) {
        return FlSpot(
          index.toDouble(), 
          (trackingData[index]['calories'] as num).toDouble()
        );
      });
    } else {
      // For month view
      return List.generate(trackingData.length, (index) {
        return FlSpot(
          index.toDouble(), 
          (trackingData[index]['calories'] as num).toDouble()
        );
      });
    }
  }

  // User profile info
  String get userName => _dashboardData?['user']?['name'] ?? 'User';
  double get userWeight => (_dashboardData?['user']?['weight'] as num?)?.toDouble() ?? 0.0;
  double get userHeight => (_dashboardData?['user']?['height'] as num?)?.toDouble() ?? 0.0;
  double get userBmr => (_dashboardData?['user']?['bmr'] as num?)?.toDouble() ?? 0.0;
  double get userTdee => (_dashboardData?['user']?['tdee'] as num?)?.toDouble() ?? 0.0;

  // Calories info
  double get caloriesConsumed => (_dashboardData?['calories']?['consumed'] as num?)?.toDouble() ?? 0.0;
  double get caloriesBurned => (_dashboardData?['calories']?['burnedFromActivities'] as num?)?.toDouble() ?? 0.0;
  double get caloriesBmr => (_dashboardData?['calories']?['bmr'] as num?)?.toDouble() ?? 0.0;
  double get caloriesTdee => (_dashboardData?['calories']?['tdee'] as num?)?.toDouble() ?? 0.0;
  double get caloriesNet => (_dashboardData?['calories']?['net'] as num?)?.toDouble() ?? 0.0;
  double get caloriesTarget => (_dashboardData?['calories']?['target'] as num?)?.toDouble() ?? 0.0;

  // Activities info
  int get activitiesCount => (_dashboardData?['activities']?['count'] as num?)?.toInt() ?? 0;
  int get activitiesTotalDuration => (_dashboardData?['activities']?['totalDuration'] as num?)?.toInt() ?? 0;
  double get activitiesTotalCaloriesBurned => (_dashboardData?['activities']?['totalCaloriesBurned'] as num?)?.toDouble() ?? 0.0;

  // Weight goal info
  double get weightGoalStartWeight => (_dashboardData?['weightGoal']?['startWeight'] as num?)?.toDouble() ?? 0.0;
  double get weightGoalTargetWeight => (_dashboardData?['weightGoal']?['targetWeight'] as num?)?.toDouble() ?? 0.0;
  String get weightGoalStartDate => _dashboardData?['weightGoal']?['startDate']?.toString() ?? '';
  String get weightGoalTargetDate => _dashboardData?['weightGoal']?['targetDate']?.toString() ?? '';

  // BMI info
  double get bmiValue => (_dashboardData?['latestBMI']?['bmi'] as num?)?.toDouble() ?? 0.0;
  String get bmiStatus => _dashboardData?['latestBMI']?['status']?.toString() ?? 'UNKNOWN';
  
  // Nutrition summary
  Map<String, dynamic>? get nutritionSummary => _dashboardData?['latestBMI']?['nutritionSummary'];
  
  // Chart labels
  List<String> get chartLabels {
    if (_dashboardData == null || 
        _dashboardData!['caloriesTracker'] == null) {
      return [];
    }

    final List<dynamic> trackingData = _dashboardData!['caloriesTracker'];
    
    if (_timeRange == 'week') {
      return trackingData.map<String>((item) => item['label'].toString()).toList();
    } else {
      // For month view
      return trackingData.map<String>((item) => item['label'].toString()).toList();
    }
  }

  // Load dashboard data
  Future<void> loadDashboardData({String? date, String range = 'week'}) async {
    _setLoading(true);
    _clearError();
    _timeRange = range;

    try {
      final response = await _userService.getDashboardData(
        date: date,
        range: range,
      );

      if (response?.success == true && response?.data != null) {
        _dashboardData = response!.data;
        notifyListeners();
      } else {
        _error = response?.message ?? 'Failed to load dashboard data';
      }
    } on HttpException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Change time range
  void changeTimeRange(String range) {
    if (_timeRange != range) {
      _timeRange = range;
      loadDashboardData(range: range);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}