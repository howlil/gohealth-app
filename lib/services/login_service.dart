import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/login_model.dart';
import '../models/registration_model.dart';
import '../utils/api_endpoints.dart';
import '../utils/http_exception.dart';
import '../utils/app_constants.dart';

class LoginService {
  final String baseUrl;
  final http.Client _client;

  LoginService({required this.baseUrl}) : _client = http.Client();

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final loginUrl = '$baseUrl${ApiEndpoints.login}';
      debugPrint('🔗 Login URL: $loginUrl');
      debugPrint('📤 Login request: ${request.toJson()}');

      final response = await _client
          .post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(request.toJson()),
      )
          .timeout(
        AppConstants.requestTimeout,
        onTimeout: () {
          throw HttpException(
              'Connection timeout. Please check your internet connection and try again.');
        },
      );

      debugPrint('📊 Login response status: ${response.statusCode}');
      debugPrint('📥 Login response headers: ${response.headers}');
      debugPrint('📥 Login response body: ${response.body}');

      // Tampilkan detail response untuk debugging
      _logDetailedResponse('LOGIN', response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final jsonResponse = json.decode(response.body);
          debugPrint('✅ Login success - parsed response: $jsonResponse');
          return LoginResponse.fromJson(jsonResponse);
        } catch (e) {
          debugPrint('❌ Error parsing login response: $e');
          throw HttpException('Invalid server response format: $e');
        }
      } else if (response.statusCode == 401) {
        final errorMsg =
            _extractErrorMessage(response.body, 'Invalid email or password');
        throw HttpException(errorMsg);
      } else if (response.statusCode == 404) {
        final errorMsg =
            _extractErrorMessage(response.body, 'Server endpoint not found');
        throw HttpException('API Error (404): $errorMsg');
      } else if (response.statusCode >= 500) {
        final errorMsg = _extractErrorMessage(response.body, 'Server error');
        throw HttpException('Server Error (${response.statusCode}): $errorMsg');
      } else {
        final errorMsg = _extractErrorMessage(response.body, 'Login failed');
        throw HttpException('Login failed (${response.statusCode}): $errorMsg');
      }
    } on http.ClientException catch (e) {
      debugPrint('🌐 Network error during login: $e');
      throw HttpException(
          'Network error: ${e.message}. Please check your internet connection.');
    } catch (e) {
      debugPrint('❌ Login error: $e');
      if (e is HttpException) rethrow;
      throw HttpException('Login failed: $e');
    }
  }

  Future<RegistrationResponse> register(RegistrationRequest request) async {
    try {
      final registerUrl = '$baseUrl${ApiEndpoints.register}';
      debugPrint('🔗 Registration URL: $registerUrl');
      debugPrint('📤 Registration request: ${request.toJson()}');

      final response = await _client
          .post(
        Uri.parse(registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(request.toJson()),
      )
          .timeout(
        AppConstants.requestTimeout,
        onTimeout: () {
          throw HttpException(
              'Connection timeout. Please check your internet connection and try again.');
        },
      );

      debugPrint('📊 Registration response status: ${response.statusCode}');
      debugPrint('📥 Registration response headers: ${response.headers}');
      debugPrint('📥 Registration response body: ${response.body}');

      // Tampilkan detail response untuk debugging
      _logDetailedResponse('REGISTRATION', response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final jsonResponse = json.decode(response.body);
          debugPrint('✅ Registration success - parsed response: $jsonResponse');
          return RegistrationResponse.fromJson(jsonResponse);
        } catch (e) {
          debugPrint('❌ Error parsing registration response: $e');
          throw HttpException('Invalid server response format: $e');
        }
      } else if (response.statusCode == 409) {
        final errorMsg =
            _extractErrorMessage(response.body, 'Email already registered');
        throw HttpException(errorMsg);
      } else if (response.statusCode == 404) {
        final errorMsg =
            _extractErrorMessage(response.body, 'Server endpoint not found');
        throw HttpException('API Error (404): $errorMsg');
      } else if (response.statusCode >= 500) {
        final errorMsg = _extractErrorMessage(response.body, 'Server error');
        throw HttpException('Server Error (${response.statusCode}): $errorMsg');
      } else {
        final errorMsg =
            _extractErrorMessage(response.body, 'Registration failed');
        throw HttpException(
            'Registration failed (${response.statusCode}): $errorMsg');
      }
    } on http.ClientException catch (e) {
      debugPrint('🌐 Network error during registration: $e');
      throw HttpException(
          'Network error: ${e.message}. Please check your internet connection.');
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      if (e is HttpException) rethrow;
      throw HttpException('Registration failed: $e');
    }
  }

  // Helper method untuk log detail response
  void _logDetailedResponse(String operation, http.Response response) {
    debugPrint('📋 $operation Response Details:');
    debugPrint('   Status Code: ${response.statusCode}');
    debugPrint('   Status Text: ${_getStatusText(response.statusCode)}');
    debugPrint(
        '   Content-Type: ${response.headers['content-type'] ?? 'unknown'}');
    debugPrint(
        '   Content-Length: ${response.headers['content-length'] ?? 'unknown'}');
    debugPrint('   Response Body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      debugPrint('❌ $operation FAILED - Full Error Details:');
      debugPrint('   URL: ${response.request?.url}');
      debugPrint('   Method: ${response.request?.method}');
      debugPrint('   Headers: ${response.headers}');
    }
  }

  // Helper method untuk extract error message dari response
  String _extractErrorMessage(String responseBody, String defaultMessage) {
    try {
      final errorJson = json.decode(responseBody);

      // Coba berbagai key yang mungkin mengandung error message
      final possibleKeys = ['message', 'error', 'detail', 'msg', 'description'];

      for (String key in possibleKeys) {
        if (errorJson[key] != null) {
          return errorJson[key].toString();
        }
      }

      // Jika tidak ada key yang cocok, return default message dengan body
      return '$defaultMessage. Server response: $responseBody';
    } catch (e) {
      // Jika response body bukan JSON, return apa adanya
      return '$defaultMessage. Raw response: $responseBody';
    }
  }

  // Helper method untuk mendapatkan status text
  String _getStatusText(int statusCode) {
    switch (statusCode) {
      case 200:
        return 'OK';
      case 201:
        return 'Created';
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 409:
        return 'Conflict';
      case 422:
        return 'Unprocessable Entity';
      case 500:
        return 'Internal Server Error';
      case 502:
        return 'Bad Gateway';
      case 503:
        return 'Service Unavailable';
      default:
        return 'Unknown Status';
    }
  }
}
