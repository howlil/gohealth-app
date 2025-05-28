class User {
  final String id;
  final String name;
  final String email;
  final bool isVerified;
  final String? photoUrl;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.isVerified,
    this.photoUrl,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    bool? isVerified,
    String? photoUrl,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isVerified: isVerified ?? this.isVerified,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'isVerified': isVerified,
      'photoUrl': photoUrl,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      isVerified: json['isVerified'] as bool,
      photoUrl: json['photoUrl'] as String?,
    );
  }
}
