class AuthModel {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final int? age;
  final String? gender;
  final double? height;
  final double? weight;
  final String? activityLevel;
  final String? profileImage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AuthModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.activityLevel,
    this.profileImage,
    this.createdAt,
    this.updatedAt,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      height: json['height'] as double?,
      weight: json['weight'] as double?,
      activityLevel: json['activityLevel'] as String?,
      profileImage: json['profileImage'] as String?,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
      'profileImage': profileImage,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  AuthModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? activityLevel,
    String? profileImage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AuthModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AuthRequest {
  final String idToken;

  AuthRequest({required this.idToken});

  Map<String, dynamic> toJson() => {'idToken': idToken};
}

class AuthResponse {
  final AuthResponseData data;
  final String message;
  final bool success;

  AuthResponse({
    required this.data,
    required this.message,
    required this.success,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      data: AuthResponseData.fromJson(json['data'] as Map<String, dynamic>),
      message: json['message'] as String,
      success: json['success'] as bool,
    );
  }
}

class AuthResponseData {
  final AuthModel user;
  final String accessToken;
  final String refreshToken;

  AuthResponseData({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponseData.fromJson(Map<String, dynamic> json) {
    return AuthResponseData(
      user: AuthModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }

  AuthTokens copyWith({
    String? accessToken,
    String? refreshToken,
  }) {
    return AuthTokens(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final AuthModel? user;
  final AuthTokens? tokens;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.tokens,
    this.error,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);

  factory AuthState.authenticated({
    required AuthModel user,
    required AuthTokens tokens,
  }) =>
      AuthState(
        status: AuthStatus.authenticated,
        user: user,
        tokens: tokens,
      );

  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);

  factory AuthState.error(String message) =>
      AuthState(status: AuthStatus.error, error: message);
}
