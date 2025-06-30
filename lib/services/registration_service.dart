import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/registration_model.dart';
import '../utils/api_endpoints.dart';
import '../utils/http_exception.dart';

class RegistrationService {
  final String baseUrl;
  final http.Client _client;

  RegistrationService({required this.baseUrl}) : _client = http.Client();

  // Register a new user
  Future<RegistrationResponse> register(RegistrationRequest request) async {
    // Coba beberapa kemungkinan endpoint
    final List<String> possibleEndpoints = [
      '/auth/register', // Tanpa /api prefix
      '/api/auth/register', // Dengan /api prefix
      '/register', // Langsung ke /register
    ];

    String lastError = '';

    for (String endpoint in possibleEndpoints) {
      try {
        final response = await _client.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(request.toJson()),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return RegistrationResponse.fromJson(json.decode(response.body));
        } else if (response.statusCode == 404) {
          // 404 berarti endpoint tidak ditemukan, coba endpoint berikutnya
          lastError = 'Endpoint $endpoint not found';
          continue;
        } else {
          throw HttpException('Registration failed: ${response.body}');
        }
      } catch (e) {
        if (e is HttpException) rethrow;
        lastError = 'Registration failed: $e';
        continue;
      }
    }

    // Jika semua endpoint gagal
    throw HttpException(
        'All registration endpoints failed. Last error: $lastError');
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
