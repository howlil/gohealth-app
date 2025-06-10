class Profile {
  final String name;
  final String email;
  final String? photoUrl;
  final String gender;
  final int age;
  final double height;
  final double weight;
  final String activityLevel;
  final String goal;

  Profile({
    required this.name,
    required this.email,
    this.photoUrl,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    required this.activityLevel,
    required this.goal,
  });

  Profile copyWith({
    String? name,
    String? email,
    String? photoUrl,
    String? gender,
    int? age,
    double? height,
    double? weight,
    String? activityLevel,
    String? goal,
  }) {
    return Profile(
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'gender': gender,
      'age': age,
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
      'goal': goal,
    };
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      name: json['name'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
      gender: json['gender'] as String,
      age: json['age'] as int,
      height: json['height'] as double,
      weight: json['weight'] as double,
      activityLevel: json['activityLevel'] as String,
      goal: json['goal'] as String,
    );
  }
}
