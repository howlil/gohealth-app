class ProfileModel {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? address;
  final String? photoUrl;
  final String? profileImage;
  final double? height;
  final double? weight;
  final String? gender;
  final String? activityLevel;
  final int? age;

  ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.address,
    this.photoUrl,
    this.profileImage,
    this.height,
    this.weight,
    this.gender,
    this.activityLevel,
    this.age,
  });

  double? get bmr {
    if (weight == null || height == null || age == null || gender == null) {
      return null;
    }

    // Mifflin-St Jeor Equation
    if (gender!.toUpperCase() == 'MALE') {
      return (10 * weight!) + (6.25 * height!) - (5 * age!) + 5;
    } else {
      return (10 * weight!) + (6.25 * height!) - (5 * age!) - 161;
    }
  }

  double? get tdee {
    if (bmr == null || activityLevel == null) return null;

    final activityMultiplier = switch (activityLevel!.toUpperCase()) {
      'SEDENTARY' => 1.2,
      'LIGHTLY_ACTIVE' => 1.375,
      'MODERATELY_ACTIVE' => 1.55,
      'VERY_ACTIVE' => 1.725,
      'EXTRA_ACTIVE' => 1.9,
      _ => 1.2,
    };

    return bmr! * activityMultiplier;
  }

  ProfileModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? address,
    String? photoUrl,
    String? profileImage,
    double? height,
    double? weight,
    String? gender,
    String? activityLevel,
    int? age,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      profileImage: profileImage ?? this.profileImage,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      age: age ?? this.age,
    );
  }
}
