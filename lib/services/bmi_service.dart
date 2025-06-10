import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/api_response_model.dart';
import '../models/ibm_history.dart';
import '../utils/env_config.dart';
import '../api/endpoints.dart';
import '../utils/app_constants.dart';
import '../utils/storage_util.dart';

class BMIService {
  static final BMIService _instance = BMIService._internal();
  factory BMIService() => _instance;
  BMIService._internal();

  // Get authentication headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await StorageUtil.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  // Get BMI history
  Future<ApiResponse<List<IBMHistory>>?> getBMIHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('${EnvConfig.apiBaseUrl}${ApiEndpoints.bmi}'),
            headers: headers,
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> bmiList = data['data'] as List;
        final List<IBMHistory> bmiHistory =
            bmiList.map((item) => IBMHistory.fromJson(item)).toList();

        return ApiResponse<List<IBMHistory>>(
          success: true,
          message: data['message'] ?? 'BMI history retrieved successfully',
          data: bmiHistory,
        );
      } else if (response.statusCode == 401) {
        debugPrint('Token expired, need to refresh');
        return null;
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<List<IBMHistory>>(
          success: false,
          message: errorData['message'] ?? 'Failed to get BMI history',
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
      final headers = await _getHeaders();
      final body = json.encode({
        'weight': weight,
        'height': height,
      });

      final response = await http
          .post(
            Uri.parse('${EnvConfig.apiBaseUrl}${ApiEndpoints.bmi}'),
            headers: headers,
            body: body,
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final bmiRecord = IBMHistory.fromJson(data['data']);
        return ApiResponse<IBMHistory>(
          success: true,
          message: data['message'] ?? 'BMI record added successfully',
          data: bmiRecord,
        );
      } else if (response.statusCode == 401) {
        debugPrint('Token expired, need to refresh');
        return null;
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<IBMHistory>(
          success: false,
          message: errorData['message'] ?? 'Failed to add BMI record',
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
  static double calculateBMI(double weight, double height) {
    // Convert height from cm to meters
    double heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  // Get BMI category
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi >= 18.5 && bmi < 25) {
      return 'Normal';
    } else if (bmi >= 25 && bmi < 30) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }
}
