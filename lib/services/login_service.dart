import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/login_model.dart';
import '../models/api_response_model.dart';
import '../models/registration_model.dart';
import '../utils/api_endpoints.dart';
import '../utils/api_service.dart';
import '../utils/storage_util.dart';
import '../utils/http_exception.dart';
import '../models/auth_model.dart';
import '../utils/app_constants.dart';

class LoginService {
  final String baseUrl;
  final http.Client _client;

  LoginService({required this.baseUrl}) : _client = http.Client();

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      debugPrint('Attempting login with email: ${request.email}');

      final response = await _client
          .post(
        Uri.parse('$baseUrl${ApiEndpoints.baseUrl}${ApiEndpoints.auth}/login'),
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

      debugPrint('Login response status: ${response.statusCode}');
      debugPrint('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = json.decode(response.body);
          return LoginResponse.fromJson(jsonResponse);
        } catch (e) {
          debugPrint('Error parsing login response: $e');
          throw HttpException('Invalid server response format');
        }
      } else if (response.statusCode == 401) {
        throw HttpException('Invalid email or password');
      } else if (response.statusCode == 404) {
        throw HttpException('Server not found. Please try again later.');
      } else if (response.statusCode >= 500) {
        throw HttpException('Server error. Please try again later.');
      } else {
        try {
          final errorJson = json.decode(response.body);
          final errorMessage =
              errorJson['message'] as String? ?? 'Login failed';
          throw HttpException(errorMessage);
        } catch (e) {
          throw HttpException('Login failed: ${response.body}');
        }
      }
    } on http.ClientException catch (e) {
      debugPrint('Network error during login: $e');
      throw HttpException(
          'Network error: ${e.message}. Please check your internet connection.');
    } catch (e) {
      debugPrint('Login error: $e');
      if (e is HttpException) rethrow;
      throw HttpException('Login failed: $e');
    }
  }

  Future<RegistrationResponse> register(RegistrationRequest request) async {
    try {
      debugPrint('Attempting registration with email: ${request.email}');

      final response = await _client
          .post(
        Uri.parse(
            '$baseUrl${ApiEndpoints.baseUrl}${ApiEndpoints.auth}/register'),
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

      debugPrint('Registration response status: ${response.statusCode}');
      debugPrint('Registration response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = json.decode(response.body);
          return RegistrationResponse.fromJson(jsonResponse);
        } catch (e) {
          debugPrint('Error parsing registration response: $e');
          throw HttpException('Invalid server response format');
        }
      } else if (response.statusCode == 409) {
        throw HttpException('Email already registered');
      } else if (response.statusCode == 404) {
        throw HttpException('Server not found. Please try again later.');
      } else if (response.statusCode >= 500) {
        throw HttpException('Server error. Please try again later.');
      } else {
        try {
          final errorJson = json.decode(response.body);
          final errorMessage =
              errorJson['message'] as String? ?? 'Registration failed';
          throw HttpException(errorMessage);
        } catch (e) {
          throw HttpException('Registration failed: ${response.body}');
        }
      }
    } on http.ClientException catch (e) {
      debugPrint('Network error during registration: $e');
      throw HttpException(
          'Network error: ${e.message}. Please check your internet connection.');
    } catch (e) {
      debugPrint('Registration error: $e');
      if (e is HttpException) rethrow;
      throw HttpException('Registration failed: $e');
    }
  }
}
