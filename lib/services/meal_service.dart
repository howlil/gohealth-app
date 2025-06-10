import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/api_response_model.dart';
import '../models/food_model.dart';
import '../utils/env_config.dart';
import '../api/endpoints.dart';
import '../utils/app_constants.dart';
import '../utils/storage_util.dart';

class MealService {
  static final MealService _instance = MealService._internal();
  factory MealService() => _instance;
  MealService._internal();

  // Get authentication headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await StorageUtil.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  // Get user meals for a specific date
  Future<ApiResponse<List<Food>>?> getMeals({String? date}) async {
    try {
      final headers = await _getHeaders();
      String url = '${EnvConfig.apiBaseUrl}${ApiEndpoints.meals}';
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
        final List<dynamic> mealsList = data['data'] as List;
        final List<Food> meals =
            mealsList.map((item) => Food.fromJson(item)).toList();

        return ApiResponse<List<Food>>(
          success: true,
          message: data['message'] ?? 'Meals retrieved successfully',
          data: meals,
        );
      } else if (response.statusCode == 401) {
        debugPrint('Token expired, need to refresh');
        return null;
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<List<Food>>(
          success: false,
          message: errorData['message'] ?? 'Failed to get meals',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error getting meals: $e');
      return ApiResponse<List<Food>>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  // Add meal
  Future<ApiResponse<Food>?> addMeal({
    required String foodId,
    required String mealType,
    required double quantity,
    String? date,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'foodId': foodId,
        'mealType': mealType,
        'quantity': quantity,
        'date': date ?? DateTime.now().toIso8601String().split('T')[0],
      });

      final response = await http
          .post(
            Uri.parse('${EnvConfig.apiBaseUrl}${ApiEndpoints.meals}'),
            headers: headers,
            body: body,
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final meal = Food.fromJson(data['data']);
        return ApiResponse<Food>(
          success: true,
          message: data['message'] ?? 'Meal added successfully',
          data: meal,
        );
      } else if (response.statusCode == 401) {
        debugPrint('Token expired, need to refresh');
        return null;
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<Food>(
          success: false,
          message: errorData['message'] ?? 'Failed to add meal',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error adding meal: $e');
      return ApiResponse<Food>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  // Delete meal
  Future<ApiResponse<String>?> deleteMeal(String mealId) async {
    try {
      final headers = await _getHeaders();

      final response = await http
          .delete(
            Uri.parse('${EnvConfig.apiBaseUrl}${ApiEndpoints.meals}/$mealId'),
            headers: headers,
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse<String>(
          success: true,
          message: data['message'] ?? 'Meal deleted successfully',
          data: 'Deleted',
        );
      } else if (response.statusCode == 401) {
        debugPrint('Token expired, need to refresh');
        return null;
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<String>(
          success: false,
          message: errorData['message'] ?? 'Failed to delete meal',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error deleting meal: $e');
      return ApiResponse<String>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }
}
