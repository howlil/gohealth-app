class AppConstants {

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  
  // Default Values
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 30);
  
  // API Endpoints

  // App Information
  static const String appName = 'GoHealth';
  static const String appVersion = '1.0.0';
}