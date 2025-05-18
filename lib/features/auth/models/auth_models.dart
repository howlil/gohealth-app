import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

@JsonSerializable()
class User {
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

  const User({
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
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable()
class AuthRequest {
  final String idToken;

  const AuthRequest({
    required this.idToken,
  });

  factory AuthRequest.fromJson(Map<String, dynamic> json) => _$AuthRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AuthRequestToJson(this);
}

@JsonSerializable()
class AuthResponse {
  final bool success;
  final int statusCode;
  final String message;
  final AuthData data;
  final String? timestamp;

  const AuthResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    required this.data,
    this.timestamp,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class AuthData {
  final User user;
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final String expiresIn;

  const AuthData({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) => _$AuthDataFromJson(json);
  Map<String, dynamic> toJson() => _$AuthDataToJson(this);
}