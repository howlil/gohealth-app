import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/api_response_model.dart';
import '../models/ibm_history.dart';
import '../utils/env_config.dart';
import '../utils/api_endpoints.dart';
import '../utils/app_constants.dart';
import '../utils/storage_util.dart';
import '../utils/api_service.dart';
import '../utils/http_exception.dart';

class BMIService {
  static final BMIService _instance = BMIService._internal();
  final ApiService _apiService = ApiService();

  factory BMIService() => _instance;
  BMIService._internal();

  // Get BMI history
  Future<ApiResponse<List<IBMHistory>>?> getBMIHistory({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await _apiService.get(
        '${ApiEndpoints.bmi}/history?limit=$limit&offset=$offset',
        requiresAuth: true,
      );

      debugPrint('BMI History Response: ${json.encode(response)}');

      if (response['success'] == true) {
        // The data should be directly a List
        final dynamic rawData = response['data'];
        List<dynamic> data;

        if (rawData is List) {
          data = rawData;
        } else {
          debugPrint('Unexpected data format: ${rawData.runtimeType}');
          data = [];
        }

        final List<IBMHistory> bmiHistory = data
            .map((item) => IBMHistory.fromJson(item as Map<String, dynamic>))
            .toList();

        debugPrint('Parsed ${bmiHistory.length} BMI records');

        return ApiResponse<List<IBMHistory>>(
          success: true,
          message: response['message'] ?? 'BMI history retrieved successfully',
          data: bmiHistory,
        );
      } else {
        return ApiResponse<List<IBMHistory>>(
          success: false,
          message: response['message'] ?? 'Failed to get BMI history',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error getting BMI history: $e');
      return ApiResponse<List<IBMHistory>>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  // Add BMI record
  Future<ApiResponse<IBMHistory>?> addBMIRecord({
    required double weight,
    required double height,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.bmi,
        body: {
          'weight': weight,
          'height': height,
        },
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final bmiRecord = IBMHistory.fromJson(response['data']);
        return ApiResponse<IBMHistory>(
          success: true,
          message: response['message'] ?? 'BMI record added successfully',
          data: bmiRecord,
        );
      } else {
        return ApiResponse<IBMHistory>(
          success: false,
          message: response['message'] ?? 'Failed to add BMI record',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error adding BMI record: $e');
      return ApiResponse<IBMHistory>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  // Calculate BMI
  Future<ApiResponse<IBMHistory>?> calculateBMI({
    required double height,
    required double weight,
  }) async {
    try {
      final response = await _apiService.post(
        '${ApiEndpoints.bmi}/calculate',
        body: {
          'height': height,
          'weight': weight,
        },
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final bmiRecord = IBMHistory.fromJson(response['data']);
        return ApiResponse<IBMHistory>(
          success: true,
          message: response['message'] ?? 'BMI calculated successfully',
          data: bmiRecord,
        );
      } else {
        return ApiResponse<IBMHistory>(
          success: false,
          message: response['message'] ?? 'Failed to calculate BMI',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error calculating BMI: $e');
      return ApiResponse<IBMHistory>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  // Get BMI category
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return 'UNDERWEIGHT';
    } else if (bmi >= 18.5 && bmi < 25) {
      return 'NORMAL';
    } else if (bmi >= 25 && bmi < 30) {
      return 'OVERWEIGHT';
    } else {
      return 'OBESE';
    }
  }
}
