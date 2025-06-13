import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/registration_model.dart';
import '../utils/api_endpoints.dart';
import '../utils/api_service.dart';
import '../utils/storage_util.dart';
import '../utils/http_exception.dart';

class RegistrationService {
  final String baseUrl;
  final http.Client _client;

  RegistrationService({required this.baseUrl}) : _client = http.Client();

  // Register a new user
  Future<RegistrationResponse> register(RegistrationRequest request) async {
    try {
      final response = await _client.post(
        Uri.parse(
            '$baseUrl${ApiEndpoints.baseUrl}${ApiEndpoints.auth}/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201) {
        return RegistrationResponse.fromJson(json.decode(response.body));
      } else {
        throw HttpException('Registration failed: ${response.body}');
      }
    } catch (e) {
      throw HttpException('Registration failed: $e');
    }
  }

  // Validate password strength
  bool isPasswordStrong(String password) {
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number, 1 special character
    final RegExp passwordRegex = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])[A-Za-z\d!@#$%^&*(),.?":{}|<>]{8,}$');
    return passwordRegex.hasMatch(password);
  }

  // Validate email format
  bool isEmailValid(String email) {
    final RegExp emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }
}
