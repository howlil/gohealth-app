import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../services/user_service.dart';

class DashboardProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  DashboardData? _dashboardData;
  bool _isLoading = false;
  String? _error;

  // Getters
  DashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load dashboard data
  Future<void> loadDashboardData({String? date}) async {
    _setLoading(true);
    try {
      final response = await _userService.getDashboardData(date: date);
      if (response?.success == true && response?.data != null) {
        _dashboardData = DashboardData.fromJson(response!.data!);
        _error = null;
      } else {
        _error = response?.message ?? 'Failed to load dashboard data';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Refresh dashboard data
  Future<void> refreshDashboardData() async {
    await loadDashboardData();
  }

  // Load dashboard data for specific date
  Future<void> loadDashboardDataForDate(DateTime date) async {
    final dateString =
        date.toIso8601String().split('T')[0]; // Format: YYYY-MM-DD
    await loadDashboardData(date: dateString);
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
