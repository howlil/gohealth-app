class AuthModel {
  final String id;
  final String name;
  final String email;
  final String? profileImage;
  final String token;
  final String refreshToken;
  final int? age;
  final String? gender;
  final double? height;
  final double? weight;
  final String? activityLevel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AuthModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    required this.token,
    required this.refreshToken,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.activityLevel,
    this.createdAt,
    this.updatedAt,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profileImage: json['profileImage']?.toString(),
      token: json['token']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      age: json['age'] as int?,
      gender: json['gender']?.toString(),
      height:
          json['height'] != null ? (json['height'] as num).toDouble() : null,
      weight:
          json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      activityLevel: json['activityLevel']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'token': token,
      'refreshToken': refreshToken,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  AuthModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImage,
    String? token,
    String? refreshToken,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? activityLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AuthModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
