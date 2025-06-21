import 'package:flutter/foundation.dart';

class RegistrationRequest {
  final String name;
  final String email;
  final String password;
  final int? age;
  final String? gender;

  RegistrationRequest({
    required this.name,
    required this.email,
    required this.password,
    this.age,
    this.gender,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
    };
  }
}

class RegistrationResponse {
  final bool success;
  final String message;
  final RegistrationUser data;

  RegistrationResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory RegistrationResponse.fromJson(Map<String, dynamic> json) {
    debugPrint('Parsing RegistrationResponse: $json');
    return RegistrationResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: RegistrationUser.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class RegistrationUser {
  final String id;
  final String name;
  final String email;
  final int? age;
  final String? gender;

  RegistrationUser({
    required this.id,
    required this.name,
    required this.email,
    this.age,
    this.gender,
  });

  factory RegistrationUser.fromJson(Map<String, dynamic> json) {
    debugPrint('Parsing RegistrationUser: $json');
    return RegistrationUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      age: json['age'] != null ? int.tryParse(json['age'].toString()) : null,
      gender: json['gender']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
    };
  }
}

class RegistrationError {
  final bool success;
  final String message;
  final ErrorDetails error;

  RegistrationError({
    required this.success,
    required this.message,
    required this.error,
  });

  factory RegistrationError.fromJson(Map<String, dynamic> json) {
    return RegistrationError(
      success: json['success'] as bool,
      message: json['message'] as String,
      error: ErrorDetails.fromJson(json['error'] as Map<String, dynamic>),
    );
  }
}

class ErrorDetails {
  final int status;
  final String name;

  ErrorDetails({
    required this.status,
    required this.name,
  });

  factory ErrorDetails.fromJson(Map<String, dynamic> json) {
    return ErrorDetails(
      status: json['status'] as int,
      name: json['name'] as String,
    );
  }
}
