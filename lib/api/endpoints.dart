class ApiEndpoints {
  // Base URL
  static const String baseUrl =
      "https://piglet-amused-willingly.ngrok-free.app";

  // Auth endpoints
  static const String googleAuth = '/auth/google';
  static const String refreshToken = '/auth/refresh';
  static const String currentUser = '/auth/me';

  // User endpoints
  static const String userProfile = '/users/profile';
  static const String userProfileImage = '/users/profile/image';
  static const String userDashboard = '/users/dashboard';

  // Meal endpoints
  static const String meals = '/meals';

  // Activity endpoints
  static const String activities = '/activities';

  // BMI endpoints
  static const String bmi = '/bmi';
}
