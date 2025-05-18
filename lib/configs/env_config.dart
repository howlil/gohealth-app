class EnvConfig {
  static bool _isLoaded = false;
  
  static Future<void> load() async {
    if (_isLoaded) return;
    
    try {
      // For now, we'll just mark as loaded since flutter_dotenv might cause issues
      // In production, you can add dotenv loading here
      _isLoaded = true;
    } catch (e) {
      // Don't throw, just log the error
      print('Info: Environment file not found, using build-time configuration');
      _isLoaded = true;
    }
  }
  
  static String get googleWebClientId {
    // Try build-time configuration first
    const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    if (webClientId.isNotEmpty) return webClientId;
    
    // Fall back to a placeholder that will show an error
    return 'GOOGLE_WEB_CLIENT_ID_NOT_CONFIGURED';
  }
  
  static String get googleAndroidClientId {
    const androidClientId = String.fromEnvironment('GOOGLE_ANDROID_CLIENT_ID');
    if (androidClientId.isNotEmpty) return androidClientId;
    
    return 'GOOGLE_ANDROID_CLIENT_ID_NOT_CONFIGURED';
  }
  
  static String get googleIosClientId {
    const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
    if (iosClientId.isNotEmpty) return iosClientId;
    
    return 'GOOGLE_IOS_CLIENT_ID_NOT_CONFIGURED';
  }
  
  static String get apiBaseUrl {
    const baseUrl = String.fromEnvironment('API_BASE_URL');
    if (baseUrl.isNotEmpty) return baseUrl;
    
    // Default API URL
    return 'http://34.101.52.148:3000';
  }
}