import 'package:json_annotation/json_annotation.dart';

part 'profile_model.g.dart';

@JsonSerializable()
class ProfileModel {
  final String id;
  final String email;
  final String name;
  final int? age;
  final String? gender;
  final double? height;
  final double? weight;
  final String? activityLevel;
  final String? profileImage;
  final double? bmr;
  final double? tdee;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileModel({
    required this.id,
    required this.email,
    required this.name,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.activityLevel,
    this.profileImage,
    this.bmr,
    this.tdee,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => 
      _$ProfileModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$ProfileModelToJson(this);

  ProfileModel copyWith({
    String? id,
    String? email,
    String? name,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? activityLevel,
    String? profileImage,
    double? bmr,
    double? tdee,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      profileImage: profileImage ?? this.profileImage,
      bmr: bmr ?? this.bmr,
      tdee: tdee ?? this.tdee,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@JsonSerializable()
class UpdateProfileRequest {
  final String? name;
  final int? age;
  final String? gender;
  final double? height;
  final double? weight;
  final String? activityLevel;

  const UpdateProfileRequest({
    this.name,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.activityLevel,
  });

  factory UpdateProfileRequest.fromJson(Map<String, dynamic> json) => 
      _$UpdateProfileRequestFromJson(json);
  
  Map<String, dynamic> toJson() => _$UpdateProfileRequestToJson(this);
}

@JsonSerializable()
class ProfileResponse {
  final bool success;
  final int statusCode;
  final String message;
  final ProfileModel data;
  final String? timestamp;

  const ProfileResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    required this.data,
    this.timestamp,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) => 
      _$ProfileResponseFromJson(json);
  
  Map<String, dynamic> toJson() => _$ProfileResponseToJson(this);
}