class LocalUser {
  final String id;
  final String name;
  final String email;
  final int? age;
  final double? height;
  final double? weight;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  LocalUser({
    required this.id,
    required this.name,
    required this.email,
    this.age,
    this.height,
    this.weight,
    this.profileImage,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  // Convert from Map (SQLite result)
  factory LocalUser.fromMap(Map<String, dynamic> map) {
    return LocalUser(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      age: map['age'] as int?,
      height: map['height'] as double?,
      weight: map['weight'] as double?,
      profileImage: map['profile_image'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: (map['is_synced'] as int) == 1,
    );
  }

  // Convert to Map (for SQLite insert/update)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'height': height,
      'weight': weight,
      'profile_image': profileImage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  // Create copy with updated fields
  LocalUser copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    double? height,
    double? weight,
    String? profileImage,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return LocalUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  String toString() {
    return 'LocalUser{id: $id, name: $name, email: $email, age: $age, height: $height, weight: $weight, isSynced: $isSynced}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}

class LocalUserSession {
  final int? id;
  final String userId;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final bool isActive;

  LocalUserSession({
    this.id,
    required this.userId,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    required this.createdAt,
    this.isActive = true,
  });

  factory LocalUserSession.fromMap(Map<String, dynamic> map) {
    return LocalUserSession(
      id: map['id'] as int?,
      userId: map['user_id'] as String,
      accessToken: map['access_token'] as String?,
      refreshToken: map['refresh_token'] as String?,
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      isActive: (map['is_active'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  LocalUserSession copyWith({
    int? id,
    String? userId,
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return LocalUserSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'LocalUserSession{id: $id, userId: $userId, isActive: $isActive}';
  }
}
