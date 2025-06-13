import 'package:flutter/foundation.dart';
import 'package:gohealth/models/auth_model.dart';

class UserProfileResponse {
  final bool success;
  final String message;
  final UserProfileData data;

  UserProfileResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    debugPrint('Parsing UserProfileResponse: $json');
    return UserProfileResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: UserProfileData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class UserProfileData {
  final String id;
  final String name;
  final String email;
  final String? profileImage;
  final String? gender;
  final int? age;
  final double? height;
  final double? weight;
  final String? activityLevel;
  final String token;

  UserProfileData({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    this.gender,
    this.age,
    this.height,
    this.weight,
    this.activityLevel,
    required this.token,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'gender': gender,
      'age': age,
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
      'token': token,
    };
  }

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      profileImage: json['profileImage'] as String?,
      gender: json['gender'] as String?,
      age: json['age'] as int?,
      height:
          json['height'] != null ? (json['height'] as num).toDouble() : null,
      weight:
          json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      activityLevel: json['activityLevel'] as String?,
      token: json['token'] as String,
    );
  }

  UserProfileData copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? activityLevel,
    String? profileImage,
    String? token,
  }) {
    return UserProfileData(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      profileImage: profileImage ?? this.profileImage,
      token: token ?? this.token,
    );
  }

  AuthModel toAuthModel() {
    return AuthModel(
      id: id,
      name: name,
      email: email,
      profileImage: profileImage,
      token: token,
    );
  }
}
