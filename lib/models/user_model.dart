import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

enum Gender { male, female }

enum ActivityLevel {
  sedentary,
  lightly,
  active,
  moderatelyActive,
  veryActive,
  extraActive
}

@JsonSerializable()
class User {
  final String id;
  final String email;
  final String name;
  final int? age;
  final Gender? gender;
  final double? height;
  final double? weight;
  final ActivityLevel? activityLevel;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.activityLevel,
    this.profileImage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
} 