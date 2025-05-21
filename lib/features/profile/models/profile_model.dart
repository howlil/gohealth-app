import 'package:json_annotation/json_annotation.dart';

part 'profile_model.g.dart';

@JsonSerializable()
class ProfileModel {
  final String? id;
  final String? name;
  final String? email;
  final int? age;
  final String? gender;
  final double? height;
  final double? weight;
  final String? activityLevel;
  final String? profileImage;
  final double? bmr;
  final double? tdee;

  ProfileModel({
    this.id,
    this.name,
    this.email,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.activityLevel,
    this.profileImage,
    this.bmr,
    this.tdee,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => _$ProfileModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileModelToJson(this);
} 