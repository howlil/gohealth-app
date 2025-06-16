class Profile {
  final String? id;
  final String name;
  final String email;
  final String? photoUrl;
  final String gender;
  final int age;
  final double height;
  final double weight;
  final String activityLevel;
  final String? goal;
  final double? bmr;
  final double? tdee;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Profile({
    this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    required this.activityLevel,
    this.goal,
    this.bmr,
    this.tdee,
    this.createdAt,
    this.updatedAt,
  });

  Profile copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? gender,
    int? age,
    double? height,
    double? weight,
    String? activityLevel,
    String? goal,
    double? bmr,
    double? tdee,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      bmr: bmr ?? this.bmr,
      tdee: tdee ?? this.tdee,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'gender': gender,
      'age': age,
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
      'goal': goal,
      'bmr': bmr,
      'tdee': tdee,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String?,
      name: json['name'] as String,
      email: json['email'] as String,
      photoUrl: json['profileImage'] as String?, // Backend uses 'profileImage'
      gender: json['gender'] as String,
      age: json['age'] as int,
      height: (json['height'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      activityLevel: json['activityLevel'] as String,
      goal: json['goal'] as String?,
      bmr: json['bmr'] != null ? (json['bmr'] as num).toDouble() : null,
      tdee: json['tdee'] != null ? (json['tdee'] as num).toDouble() : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}