import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../utils/api_endpoints.dart';
import '../utils/storage_util.dart';
import '../utils/env_config.dart';
import '../services/auth_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  final String _baseUrl = EnvConfig.apiBaseUrl;
  final Logger logger = Logger();
  final AuthService _authService = AuthService();
  bool _isRefreshing = false;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  // Get auth headers with token
  Future<Map<String, String>> getHeaders() async {
    final token = await StorageUtil.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      'User-Agent': 'GoHealth-Flutter-App/1.0.0',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Refresh token
  Future<bool> _refreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;
    try {
      final refreshToken = await StorageUtil.getRefreshToken();
      if (refreshToken == null) {
        logger.e("No refresh token available");
        return false;
      }
      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/api/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'User-Agent': 'GoHealth-Flutter-App/1.0.0',
        },
        body: json.encode({'refreshToken': refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          await StorageUtil.setAccessToken(data['data']['accessToken']);
          await StorageUtil.setRefreshToken(data['data']['refreshToken']);
          logger.d("Token refreshed successfully");
          return true;
        }
      }
      logger.e("Token refresh failed: ${response.body}");
      return false;
    } catch (e) {
      logger.e("Token refresh error: $e");
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  // Perform GET request with token refresh
  Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = true,
    Map<String, String>? queryParams,
  }) async {
    try {
      var headers = await getHeaders();
      var uri = Uri.parse('$_baseUrl$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      logger.d("GET Request: $uri");
      var response = await http.get(uri, headers: headers);
      logger.d("Response Status: ${response.statusCode}");
      // Handle token refresh if needed
      if (response.statusCode == 401 && requiresAuth) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          headers = await getHeaders();
          response = await http.get(uri, headers: headers);
          logger.d("Retry Response Status: ${response.statusCode}");
        }
      }
      logger.d(
          "Response Body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...");
      return _handleResponse(response);
    } catch (e) {
      logger.e("GET Error: $e");
      return {"success": false, "message": "Network error occurred: $e"};
    }
  }

  // Perform POST request with token refresh
  Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> body,
    bool requiresAuth = true,
  }) async {
    try {
      var headers = await getHeaders();
      final url = Uri.parse('$_baseUrl$endpoint');
      logger.d("POST Request: $url");
      logger.d("POST Body: $body");
      var response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      // Handle token refresh if needed
      if (response.statusCode == 401 && requiresAuth) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          headers = await getHeaders();
          response = await http.post(
            url,
            headers: headers,
            body: jsonEncode(body),
          );
          logger.d("Retry Response Status: ${response.statusCode}");
        }
      }
      logger.d("Response Status: ${response.statusCode}");
      logger.d(
          "Response Body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...");
      return _handleResponse(response);
    } catch (e) {
      logger.e("POST Error: $e");
      return {"success": false, "message": "Network error occurred: $e"};
    }
  }

  // Perform PUT request with token refresh
  Future<Map<String, dynamic>> put(
    String endpoint, {
    required Map<String, dynamic> body,
    bool requiresAuth = true,
  }) async {
    try {
      var headers = await getHeaders();
      final url = Uri.parse('$_baseUrl$endpoint');
      logger.d("PUT Request: $url");
      logger.d("PUT Body: $body");
      var response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      // Handle token refresh if needed
      if (response.statusCode == 401 && requiresAuth) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          headers = await getHeaders();
          response = await http.put(
            url,
            headers: headers,
            body: jsonEncode(body),
          );
          logger.d("Retry Response Status: ${response.statusCode}");
        }
      }
      logger.d("Response Status: ${response.statusCode}");
      logger.d(
          "Response Body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...");
      return _handleResponse(response);
    } catch (e) {
      logger.e("PUT Error: $e");
      return {"success": false, "message": "Network error occurred: $e"};
    }
  }

  // Perform PATCH request with token refresh
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    required Map<String, dynamic> body,
    bool requiresAuth = true,
  }) async {
    try {
      var headers = await getHeaders();
      final url = Uri.parse('$_baseUrl$endpoint');
      logger.d("PATCH Request: $url");
      logger.d("PATCH Body: $body");

      var request = http.Request('PATCH', url);
      request.headers.addAll(headers);
      request.body = jsonEncode(body);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Handle token refresh if needed
      if (response.statusCode == 401 && requiresAuth) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          headers = await getHeaders();
          request = http.Request('PATCH', url);
          request.headers.addAll(headers);
          request.body = jsonEncode(body);
          streamedResponse = await request.send();
          response = await http.Response.fromStream(streamedResponse);
          logger.d("Retry Response Status: ${response.statusCode}");
        }
      }

      logger.d("Response Status: ${response.statusCode}");
      logger.d(
          "Response Body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...");
      return _handleResponse(response);
    } catch (e) {
      logger.e("PATCH Error: $e");
      return {"success": false, "message": "Network error occurred: $e"};
    }
  }

  // Perform DELETE request with token refresh
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      var headers = await getHeaders();
      final url = Uri.parse('$_baseUrl$endpoint');
      logger.d("DELETE Request: $url");
      if (body != null) {
        logger.d("DELETE Body: $body");
      }

      var request = http.Request('DELETE', url);
      request.headers.addAll(headers);
      if (body != null) {
        request.body = jsonEncode(body);
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Handle token refresh if needed
      if (response.statusCode == 401 && requiresAuth) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          headers = await getHeaders();
          request = http.Request('DELETE', url);
          request.headers.addAll(headers);
          if (body != null) {
            request.body = jsonEncode(body);
          }
          streamedResponse = await request.send();
          response = await http.Response.fromStream(streamedResponse);
          logger.d("Retry Response Status: ${response.statusCode}");
        }
      }

      logger.d("Response Status: ${response.statusCode}");
      logger.d(
          "Response Body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...");
      return _handleResponse(response);
    } catch (e) {
      logger.e("DELETE Error: $e");
      return {"success": false, "message": "Network error occurred: $e"};
    }
  }

  // Handle API response
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      logger.d("Response Status Code: ${response.statusCode}");
      logger.d("Response Headers: ${response.headers}");
      logger.d("Raw Response Body: ${response.body}");

      // Check if response body is empty
      if (response.body.isEmpty) {
        logger.w("Empty response body received");
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {
            "success": true,
            "data": null,
            "message": "Success - No content"
          };
        } else {
          return {
            "success": false,
            "message":
                "Empty response with error status: ${response.statusCode}",
            "statusCode": response.statusCode
          };
        }
      }

      // Try to parse JSON
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          "success": true,
          "data": data['data'],
          "message": data['message'] ?? "Success"
        };
      } else {
        String errorMessage = "Unknown error occurred";

        // Try to extract error message from different response formats
        if (data is Map<String, dynamic>) {
          errorMessage = data["message"] ??
              data["error"] ??
              data["errors"]?.toString() ??
              "Server error: ${response.statusCode}";
        } else if (data is String) {
          errorMessage = data;
        }

        logger.e("API Error: $errorMessage (Status: ${response.statusCode})");

        return {
          "success": false,
          "message": errorMessage,
          "statusCode": response.statusCode
        };
      }
    } catch (e) {
      logger.e("Response parsing error: $e");
      logger.e("Response body that failed to parse: ${response.body}");
      logger.e("Response status code: ${response.statusCode}");

      // Return more informative error message
      String errorMessage = "Server response tidak dapat diproses";

      if (response.statusCode == 404) {
        errorMessage = "Endpoint tidak ditemukan. Silakan coba lagi nanti.";
      } else if (response.statusCode == 500) {
        errorMessage = "Terjadi kesalahan server. Silakan coba lagi nanti.";
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        errorMessage = "Permintaan tidak valid. Silakan periksa data Anda.";
      } else if (response.body.contains("<!DOCTYPE html") ||
          response.body.contains("<html")) {
        errorMessage = "Server sedang maintenance. Silakan coba lagi nanti.";
      }

      return {
        "success": false,
        "message": errorMessage,
        "statusCode": response.statusCode,
        "rawError": e.toString()
      };
    }
  }
}
