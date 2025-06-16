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
  Future<void> loadDashboardData() async {
    _setLoading(true);
    try {
      final response = await _userService.getDashboardData();
      if (response?.success == true && response?.data != null) {
        final data = response!.data;
        if (data != null) {
          _dashboardData = DashboardData.fromJson(data);
          _error = null;
        } else {
          _error = 'Invalid dashboard data received';
        }
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
    await loadDashboardData();
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
