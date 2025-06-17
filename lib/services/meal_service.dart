import 'package:flutter/foundation.dart' show debugPrint;
import '../models/api_response_model.dart';
import '../models/food_model.dart';
import '../models/meal_model.dart';
import '../utils/api_endpoints.dart';
import '../utils/api_service.dart';

class MealService {
  static final MealService _instance = MealService._internal();
  final ApiService _apiService = ApiService();

  factory MealService() => _instance;
  MealService._internal();

  // Get food list with pagination and filters
  Future<ApiResponse<Map<String, dynamic>>?> getFoods({
    String? search,
    String? category,
    int page = 0,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final uri = Uri.parse('${ApiEndpoints.foods}')
          .replace(queryParameters: queryParams);

      final response = await _apiService.get(
        uri.toString(),
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final foods = (data['data'] as List)
            .map((item) => Food.fromJson(item as Map<String, dynamic>))
            .toList();

        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: response['message'] ?? 'Foods retrieved successfully',
          data: {
            'foods': foods,
            'pagination': data['pagination'] ?? {},
          },
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response['message'] ?? 'Failed to get foods',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error getting foods: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  // Get food categories
  Future<ApiResponse<List<FoodCategory>>?> getFoodCategories() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.foodCategories,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        final List<FoodCategory> categories = data
            .map((item) => FoodCategory.fromJson(item as Map<String, dynamic>))
            .toList();

        return ApiResponse<List<FoodCategory>>(
          success: true,
          message:
              response['message'] ?? 'Food categories retrieved successfully',
          data: categories,
        );
      } else {
        return ApiResponse<List<FoodCategory>>(
          success: false,
          message: response['message'] ?? 'Failed to get food categories',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error getting food categories: $e');
      return ApiResponse<List<FoodCategory>>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  // Get food autocomplete suggestions
  Future<ApiResponse<List<Food>>?> getFoodSuggestions({
    required String query,
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.get(
        '${ApiEndpoints.foodAutocomplete}?query=$query&limit=$limit',
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        final List<Food> suggestions = data.map((item) {
          // Parse the simplified autocomplete response
          final Map<String, dynamic> foodData = item as Map<String, dynamic>;

          // Create a minimal Food object from autocomplete data
          return Food(
            id: foodData['id'] as String,
            name: foodData['name'] as String,
            calories: (foodData['calory'] as num).toDouble(),
            protein: 0, // These will be fetched when food is selected
            carbs: 0,
            fat: 0,
            category: foodData['category'] != null
                ? FoodCategory(
                    id: '',
                    name: foodData['category']['name'] as String,
                    slug: foodData['category']['slug'] as String,
                    description: '',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  )
                : null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }).toList();

        return ApiResponse<List<Food>>(
          success: true,
          message:
              response['message'] ?? 'Food suggestions retrieved successfully',
          data: suggestions,
        );
      } else {
        return ApiResponse<List<Food>>(
          success: false,
          message: response['message'] ?? 'Failed to get food suggestions',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error getting food suggestions: $e');
      debugPrint('Error details: ${e.toString()}');
      return ApiResponse<List<Food>>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  // Get favorite foods
  Future<ApiResponse<Map<String, dynamic>>?> getFavoriteFoods({
    int page = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get(
        '${ApiEndpoints.favorites}?page=$page&limit=$limit',
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final favorites = (data['data'] as List)
            .map((item) => Food.fromJson(item['food'] as Map<String, dynamic>))
            .toList();

        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message:
              response['message'] ?? 'Favorite foods retrieved successfully',
          data: {
            'foods': favorites,
            'pagination': data['pagination'] ?? {},
          },
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response['message'] ?? 'Failed to get favorite foods',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error getting favorite foods: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  // Add food to favorites
  Future<ApiResponse<void>?> addToFavorites(String foodId) async {
    try {
      final response = await _apiService.post(
        '${ApiEndpoints.favorites}/$foodId',
        body: {},
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return ApiResponse<void>(
          success: true,
          message:
              response['message'] ?? 'Food added to favorites successfully',
          data: null,
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response['message'] ?? 'Failed to add food to favorites',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error adding food to favorites: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  // Remove food from favorites
  Future<ApiResponse<void>?> removeFromFavorites(String foodId) async {
    try {
      final response = await _apiService.delete(
        '${ApiEndpoints.favorites}/$foodId',
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return ApiResponse<void>(
          success: true,
          message:
              response['message'] ?? 'Food removed from favorites successfully',
          data: null,
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message:
              response['message'] ?? 'Failed to remove food from favorites',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error removing food from favorites: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  // Get user meals with filters
  Future<ApiResponse<Map<String, dynamic>>?> getMeals({
    String? date,
    String? mealType,
    int page = 0,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (date != null && date.isNotEmpty) {
        queryParams['date'] = date;
      }

      if (mealType != null && mealType.isNotEmpty) {
        queryParams['mealType'] = mealType;
      }

      final uri =
          Uri.parse(ApiEndpoints.meals).replace(queryParameters: queryParams);

      final response = await _apiService.get(
        uri.toString(),
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final meals = (data['data'] as List)
            .map((item) => Meal.fromJson(item as Map<String, dynamic>))
            .toList();

        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: response['message'] ?? 'Meals retrieved successfully',
          data: {
            'meals': meals,
            'pagination': data['pagination'] ?? {},
          },
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response['message'] ?? 'Failed to get meals',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error getting meals: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  // Add meal
  Future<ApiResponse<Meal>?> addMeal({
    required String foodId,
    required String mealType,
    required double quantity,
    required String unit,
    String? date,
  }) async {
    try {
      // Format date to DD-MM-YYYY if not provided
      final mealDate = date ?? _formatDateToDDMMYYYY(DateTime.now());

      final response = await _apiService.post(
        ApiEndpoints.meals,
        body: {
          'foodId': foodId,
          'mealType': mealType,
          'quantity': quantity,
          'unit': unit,
          'date': mealDate,
        },
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final meal = Meal.fromJson(response['data']);
        return ApiResponse<Meal>(
          success: true,
          message: response['message'] ?? 'Meal added successfully',
          data: meal,
        );
      } else {
        return ApiResponse<Meal>(
          success: false,
          message: response['message'] ?? 'Failed to add meal',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error adding meal: $e');
      return ApiResponse<Meal>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  // Update meal
  Future<ApiResponse<Meal>?> updateMeal({
    required String mealId,
    double? quantity,
    String? unit,
    String? mealType,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (quantity != null) body['quantity'] = quantity;
      if (unit != null) body['unit'] = unit;
      if (mealType != null) body['mealType'] = mealType;

      final response = await _apiService.put(
        '${ApiEndpoints.meals}/$mealId',
        body: body,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final meal = Meal.fromJson(response['data']);
        return ApiResponse<Meal>(
          success: true,
          message: response['message'] ?? 'Meal updated successfully',
          data: meal,
        );
      } else {
        return ApiResponse<Meal>(
          success: false,
          message: response['message'] ?? 'Failed to update meal',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error updating meal: $e');
      return ApiResponse<Meal>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  // Delete meal
  Future<ApiResponse<void>?> deleteMeal(String mealId) async {
    try {
      final response = await _apiService.delete(
        '${ApiEndpoints.meals}/$mealId',
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return ApiResponse<void>(
          success: true,
          message: response['message'] ?? 'Meal deleted successfully',
          data: null,
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response['message'] ?? 'Failed to delete meal',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error deleting meal: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  // Get daily meal summary
  Future<ApiResponse<DailyMealSummary>?> getDailyMealSummary({
    required String date,
  }) async {
    try {
      final response = await _apiService.get(
        '${ApiEndpoints.meals}/summary?date=$date',
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final summary = DailyMealSummary.fromJson(response['data']);
        return ApiResponse<DailyMealSummary>(
          success: true,
          message: response['message'] ??
              'Daily meal summary retrieved successfully',
          data: summary,
        );
      } else {
        return ApiResponse<DailyMealSummary>(
          success: false,
          message: response['message'] ?? 'Failed to get daily meal summary',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error getting daily meal summary: $e');
      return ApiResponse<DailyMealSummary>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  // Helper method to format date
  String _formatDateToDDMMYYYY(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }
}
