import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../utils/api_endpoints.dart';
import '../utils/storage_util.dart';
import '../utils/env_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  final String _baseUrl = EnvConfig.apiBaseUrl;
  final Logger logger = Logger();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  // Get auth headers with token
  Future<Map<String, String>> _getHeaders() async {
    final token = await StorageUtil.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Perform GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = true,
    Map<String, String>? queryParams,
  }) async {
    try {
      final headers = await _getHeaders();
      var uri = Uri.parse('$_baseUrl$endpoint');

      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      logger.d("GET Request: $uri");
      final response = await http.get(uri, headers: headers);
      logger.d("Response Status: ${response.statusCode}");
      logger.d(
          "Response Body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...");

      return _handleResponse(response);
    } catch (e) {
      logger.e("GET Error: $e");
      return {"success": false, "message": "Network error occurred: $e"};
    }
  }

  // Perform POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> body,
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$_baseUrl$endpoint');

      logger.d("POST Request: $url");
      logger.d("POST Body: $body");

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      logger.d("Response Status: ${response.statusCode}");
      logger.d(
          "Response Body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...");

      return _handleResponse(response);
    } catch (e) {
      logger.e("POST Error: $e");
      return {"success": false, "message": "Network error occurred: $e"};
    }
  }

  // Handle API response
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {"success": true, "data": data};
      } else {
        String errorMessage = data["error"] ?? "Unknown error occurred";
        return {
          "success": false,
          "message": errorMessage,
          "statusCode": response.statusCode
        };
      }
    } catch (e) {
      logger.e("Response parsing error: $e");
      return {
        "success": false,
        "message": "Failed to process response",
        "statusCode": response.statusCode
      };
    }
  }
}
