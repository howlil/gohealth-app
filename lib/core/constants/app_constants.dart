class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://34.101.52.148:3000';
  static const String apiVersion = '/api/v1';
  static const String apiUrl = '$baseUrl$apiVersion';
  
  // Google OAuth Configuration
  static const String googleWebClientId = '845113946067-ukaickbhgki6n6phesnacsa9b4sgc8hu.apps.googleusercontent.com';
  static const String googleAndroidClientId = '845113946067-hvg4pfb2ncjicg8mh8en5ouckugkdbeh.apps.googleusercontent.com';
  static const String googleIosClientId = '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';
  
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