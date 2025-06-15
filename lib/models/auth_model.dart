class AuthModel {
  final String id;
  final String name;
  final String email;
  final String token;
  final String refreshToken;
  final String? profileImage;
  final String? gender;
  final int? age;
  final double? height;
  final double? weight;
  final String? activityLevel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AuthModel({
    required this.id,
    required this.name,
    required this.email,
    required this.token,
    required this.refreshToken,
    this.profileImage,
    this.gender,
    this.age,
    this.height,
    this.weight,
    this.activityLevel,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'token': token,
      'refreshToken': refreshToken,
      'profileImage': profileImage,
      'gender': gender,
      'age': age,
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      profileImage: json['profileImage']?.toString(),
      gender: json['gender']?.toString(),
      age: json['age'] as int?,
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

  AuthModel copyWith({
    String? id,
    String? name,
    String? email,
    String? token,
    String? refreshToken,
    String? profileImage,
    String? gender,
    int? age,
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
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      profileImage: profileImage ?? this.profileImage,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AuthModel(id: $id, name: $name, email: $email, token: $token, refreshToken: $refreshToken, profileImage: $profileImage, gender: $gender, age: $age, height: $height, weight: $weight, activityLevel: $activityLevel, createdAt: $createdAt, updatedAt: $updatedAt)';
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
      message: json['message'] as String? ?? 'Unknown message',
      success: json['success'] as bool? ?? false,
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
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
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
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
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
