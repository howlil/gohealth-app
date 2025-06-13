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
  factory BMIService() => _instance;
  BMIService._internal();

  // Get authentication headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await StorageUtil.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  // Get BMI history
  Future<ApiResponse<List<IBMHistory>>?> getBMIHistory({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final headers = await _getHeaders();
      final url =
          '${EnvConfig.apiBaseUrl}/api${ApiEndpoints.bmi}/history?limit=$limit&offset=$offset';
      debugPrint('Fetching BMI history from: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(AppConstants.requestTimeout);

      debugPrint('BMI history response status: ${response.statusCode}');
      debugPrint('BMI history response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          if (data == null) {
            return ApiResponse<List<IBMHistory>>(
              success: false,
              message: 'Invalid response format',
              data: null,
            );
          }

          final List<dynamic> bmiList = data['data'] as List? ?? [];
          debugPrint('Parsing ${bmiList.length} BMI records');

          final List<IBMHistory> bmiHistory = [];
          for (var item in bmiList) {
            try {
              final bmiRecord =
                  IBMHistory.fromJson(item as Map<String, dynamic>);
              bmiHistory.add(bmiRecord);
            } catch (e) {
              debugPrint('Error parsing BMI record: $e');
              debugPrint('Record data: $item');
            }
          }

          return ApiResponse<List<IBMHistory>>(
            success: true,
            message: data['message']?.toString() ??
                'BMI history retrieved successfully',
            data: bmiHistory,
          );
        } catch (e) {
          debugPrint('Error parsing BMI history response: $e');
          return ApiResponse<List<IBMHistory>>(
            success: false,
            message: 'Error parsing response: ${e.toString()}',
            data: null,
          );
        }
      } else if (response.statusCode == 401) {
        debugPrint('Token expired, need to refresh');
        return null;
      } else {
        try {
          final errorData = json.decode(response.body);
          return ApiResponse<List<IBMHistory>>(
            success: false,
            message:
                errorData['message']?.toString() ?? 'Failed to get BMI history',
            data: null,
          );
        } catch (e) {
          return ApiResponse<List<IBMHistory>>(
            success: false,
            message: 'Server error: ${response.statusCode}',
            data: null,
          );
        }
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
            Uri.parse('${EnvConfig.apiBaseUrl}/api${ApiEndpoints.bmi}'),
            headers: headers,
            body: body,
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 201) {
        try {
          final data = json.decode(response.body);
          if (data == null || data['data'] == null) {
            return ApiResponse<IBMHistory>(
              success: false,
              message: 'Invalid response format',
              data: null,
            );
          }

          final bmiRecord =
              IBMHistory.fromJson(data['data'] as Map<String, dynamic>);
          return ApiResponse<IBMHistory>(
            success: true,
            message:
                data['message']?.toString() ?? 'BMI record added successfully',
            data: bmiRecord,
          );
        } catch (e) {
          debugPrint('Error parsing add BMI record response: $e');
          return ApiResponse<IBMHistory>(
            success: false,
            message: 'Error parsing response: ${e.toString()}',
            data: null,
          );
        }
      } else if (response.statusCode == 401) {
        debugPrint('Token expired, need to refresh');
        return null;
      } else {
        try {
          final errorData = json.decode(response.body);
          return ApiResponse<IBMHistory>(
            success: false,
            message:
                errorData['message']?.toString() ?? 'Failed to add BMI record',
            data: null,
          );
        } catch (e) {
          return ApiResponse<IBMHistory>(
            success: false,
            message: 'Server error: ${response.statusCode}',
            data: null,
          );
        }
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
      final headers = await _getHeaders();
      final body = json.encode({
        'height': height,
        'weight': weight,
      });

      final url = '${EnvConfig.apiBaseUrl}/api${ApiEndpoints.bmi}/calculate';
      debugPrint('Calculating BMI at: $url');
      debugPrint('Request body: $body');

      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: body,
          )
          .timeout(AppConstants.requestTimeout);

      debugPrint('Calculate BMI response status: ${response.statusCode}');
      debugPrint('Calculate BMI response body: ${response.body}');

      if (response.statusCode == 201) {
        try {
          final data = json.decode(response.body);
          if (data == null || data['data'] == null) {
            return ApiResponse<IBMHistory>(
              success: false,
              message: 'Invalid response format',
              data: null,
            );
          }

          final bmiRecord =
              IBMHistory.fromJson(data['data'] as Map<String, dynamic>);
          return ApiResponse<IBMHistory>(
            success: true,
            message:
                data['message']?.toString() ?? 'BMI calculated successfully',
            data: bmiRecord,
          );
        } catch (e) {
          debugPrint('Error parsing calculate BMI response: $e');
          return ApiResponse<IBMHistory>(
            success: false,
            message: 'Error parsing response: ${e.toString()}',
            data: null,
          );
        }
      } else if (response.statusCode == 401) {
        debugPrint('Token expired, need to refresh');
        return null;
      } else {
        try {
          final errorData = json.decode(response.body);
          return ApiResponse<IBMHistory>(
            success: false,
            message:
                errorData['message']?.toString() ?? 'Failed to calculate BMI',
            data: null,
          );
        } catch (e) {
          return ApiResponse<IBMHistory>(
            success: false,
            message: 'Server error: ${response.statusCode}',
            data: null,
          );
        }
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
