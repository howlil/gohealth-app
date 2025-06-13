import 'package:flutter/foundation.dart';
import 'package:gohealth/models/auth_model.dart';

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class LoginResponse {
  final bool success;
  final String message;
  final LoginResponseData? data;

  LoginResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    debugPrint('Parsing LoginResponse: $json');
    try {
      return LoginResponse(
        success: json['success'] as bool? ?? false,
        message: json['message'] as String? ?? 'Unknown error occurred',
        data: json['data'] != null
            ? LoginResponseData.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      debugPrint('Error parsing LoginResponse: $e');
      debugPrint('JSON data: $json');
      return LoginResponse(
        success: false,
        message: 'Failed to parse server response',
      );
    }
  }
}

class LoginResponseData {
  final String id;
  final String email;
  final String name;
  final int? age;
  final String? gender;
  final double? height;
  final double? weight;
  final String? activityLevel;
  final String? profileImage;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final String? expiresIn;

  LoginResponseData({
    required this.id,
    required this.email,
    required this.name,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.activityLevel,
    this.profileImage,
    this.createdAt,
    this.updatedAt,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    this.expiresIn,
  });

  // Constructor that accepts an AuthModel
  LoginResponseData.fromAuthModel({
    required AuthModel user,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    this.expiresIn,
  })  : id = user.id,
        email = user.email,
        name = user.name,
        age = user.age,
        gender = user.gender,
        height = user.height,
        weight = user.weight,
        activityLevel = user.activityLevel,
        profileImage = user.profileImage,
        createdAt = user.createdAt,
        updatedAt = user.updatedAt;

  AuthModel toAuthModel() {
    return AuthModel(
      id: id,
      email: email,
      name: name,
      token: accessToken,
      age: age,
      gender: gender,
      height: height,
      weight: weight,
      activityLevel: activityLevel,
      profileImage: profileImage,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory LoginResponseData.fromJson(Map<String, dynamic> json) {
    debugPrint('Parsing LoginResponseData: $json');
    try {
      return LoginResponseData(
        // Use null-aware operators and provide defaults for required fields
        id: json['id']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        age: json['age'] as int?,
        gender: json['gender']?.toString(),
        height: json['height'] != null ? (json['height'] as num).toDouble() : null,
        weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
        activityLevel: json['activityLevel']?.toString(),
        profileImage: json['profileImage']?.toString(),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) // Use tryParse instead of parse
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'].toString()) // Use tryParse instead of parse
            : null,
        accessToken: json['accessToken']?.toString() ?? '',
        refreshToken: json['refreshToken']?.toString() ?? '',
        tokenType: json['tokenType']?.toString() ?? 'Bearer',
        expiresIn: json['expiresIn']?.toString(),
      );
    } catch (e) {
      debugPrint('Error parsing LoginResponseData: $e');
      debugPrint('JSON data: $json');
      rethrow;
    }
  }
}

class LoginError {
  final bool success;
  final String message;
  final ErrorDetails? error;

  LoginError({
    required this.success,
    required this.message,
    this.error,
  });

  factory LoginError.fromJson(Map<String, dynamic> json) {
    return LoginError(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? 'Unknown error',
      error: json['error'] != null
          ? ErrorDetails.fromJson(json['error'] as Map<String, dynamic>)
          : null,
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
      status: json['status'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown error',
    );
  }
}

class LoginModel {
  final String id;
  final String name;
  final String email;
  final String token;
  final String? profileImage;
  final String? gender;
  final int? age;
  final double? height;
  final double? weight;
  final String? activityLevel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LoginModel({
    required this.id,
    required this.name,
    required this.email,
    required this.token,
    this.profileImage,
    this.gender,
    this.age,
    this.height,
    this.weight,
    this.activityLevel,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'token': token,
      'profileImage': profileImage,
      'gender': gender,
      'age': age,
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      profileImage: json['profileImage']?.toString(),
      gender: json['gender']?.toString(),
      age: json['age'] as int?,
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      activityLevel: json['activityLevel']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) // Use tryParse
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) // Use tryParse
          : null,
    );
  }

  LoginModel copyWith({
    String? id,
    String? name,
    String? email,
    String? token,
    String? profileImage,
    String? gender,
    int? age,
    double? height,
    double? weight,
    String? activityLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoginModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      token: token ?? this.token,
      profileImage: profileImage ?? this.profileImage,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  AuthModel toAuthModel() {
    return AuthModel(
      id: id,
      email: email,
      name: name,
      token: token,
      age: age,
      gender: gender,
      height: height,
      weight: weight,
      activityLevel: activityLevel,
      profileImage: profileImage,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  String toString() {
    return 'LoginModel(id: $id, name: $name, email: $email, token: $token, profileImage: $profileImage, gender: $gender, age: $age, height: $height, weight: $weight, activityLevel: $activityLevel, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}