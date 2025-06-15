import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/api_response_model.dart';
import '../models/food_model.dart';
import '../models/meal_type.dart';
import '../utils/env_config.dart';
import '../utils/api_endpoints.dart';
import '../utils/app_constants.dart';
import '../utils/storage_util.dart';
import '../utils/api_service.dart';
import '../utils/http_exception.dart';

class MealService {
  static final MealService _instance = MealService._internal();
  final ApiService _apiService = ApiService();

  factory MealService() => _instance;
  MealService._internal();

  // Get user meals for a specific date
  Future<ApiResponse<List<Food>>?> getMeals({String? date}) async {
    try {
      final response = await _apiService.get(
        '${ApiEndpoints.nutrition}/meals${date != null ? '?date=$date' : ''}',
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        final List<Food> meals = data
            .map((item) => Food.fromJson(item as Map<String, dynamic>))
            .toList();

        return ApiResponse<List<Food>>(
          success: true,
          message: response['message'] ?? 'Meals retrieved successfully',
          data: meals,
        );
      } else {
        return ApiResponse<List<Food>>(
          success: false,
          message: response['message'] ?? 'Failed to get meals',
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
      final response = await _apiService.post(
        '${ApiEndpoints.nutrition}/meals',
        body: {
          'foodId': foodId,
          'mealType': mealType,
          'quantity': quantity,
          'date': date ?? DateTime.now().toIso8601String().split('T')[0],
        },
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final meal = Food.fromJson(response['data']);
        return ApiResponse<Food>(
          success: true,
          message: response['message'] ?? 'Meal added successfully',
          data: meal,
        );
      } else {
        return ApiResponse<Food>(
          success: false,
          message: response['message'] ?? 'Failed to add meal',
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
      final response = await _apiService.get(
        '${ApiEndpoints.nutrition}/meals/$mealId',
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return ApiResponse<String>(
          success: true,
          message: response['message'] ?? 'Meal deleted successfully',
          data: 'Deleted',
        );
      } else {
        return ApiResponse<String>(
          success: false,
          message: response['message'] ?? 'Failed to delete meal',
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
