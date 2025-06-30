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
  final String? token;
  final String? refreshToken;
  final double? bmr;
  final double? tdee;
  final String? createdAt;
  final String? updatedAt;

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
    this.token,
    this.refreshToken,
    this.bmr,
    this.tdee,
    this.createdAt,
    this.updatedAt,
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
      'refreshToken': refreshToken,
      'bmr': bmr,
      'tdee': tdee,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profileImage: json['profileImage']?.toString(),
      gender: json['gender']?.toString(),
      age: json['age'] != null ? int.tryParse(json['age'].toString()) : null,
      height: json['height'] != null
          ? double.tryParse(json['height'].toString())
          : null,
      weight: json['weight'] != null
          ? double.tryParse(json['weight'].toString())
          : null,
      activityLevel: json['activityLevel']?.toString(),
      token: json['token']?.toString(),
      refreshToken: json['refreshToken']?.toString(),
      bmr: json['bmr'] != null ? double.tryParse(json['bmr'].toString()) : null,
      tdee: json['tdee'] != null
          ? double.tryParse(json['tdee'].toString())
          : null,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
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
    String? refreshToken,
    double? bmr,
    double? tdee,
    String? createdAt,
    String? updatedAt,
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
      refreshToken: refreshToken ?? this.refreshToken,
      bmr: bmr ?? this.bmr,
      tdee: tdee ?? this.tdee,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  AuthModel toAuthModel() {
    return AuthModel(
      id: id,
      name: name,
      email: email,
      profileImage: profileImage,
      token: token ?? '',
      refreshToken: refreshToken ?? '',
    );
  }
}

class UserProfile {
  final String id;
  final String email;
  final String name;
  final int age;
  final String gender;
  final double height;
  final double weight;
  final String? activityLevel;
  final String? profileImage;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    this.activityLevel,
    this.profileImage,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      gender: json['gender']?.toString() ?? '',
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      activityLevel: json['activityLevel']?.toString(),
      profileImage: json['profileImage']?.toString(),
    );
  }
}
