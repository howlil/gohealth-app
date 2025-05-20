class EnvConfig {
  static bool _isLoaded = false;
  
  static Future<void> load() async {
    if (_isLoaded) return;
    
    try {
      // Use Flutter dotenv if available
      // await dotenv.load(fileName: ".env");
      _isLoaded = true;
    } catch (e) {
      print('Info: Environment file not found, using hardcoded configuration');
      _isLoaded = true;
    }
  }
  
  static String get googleWebClientId {
    // These values should match your provided client IDs
    return '845113946067-ukaickbhgki6n6phesnacsa9b4sgc8hu.apps.googleusercontent.com';
  }
  
  static String get googleAndroidClientId {
    return '845113946067-hvg4pfb2ncjicg8mh8en5ouckugkdbeh.apps.googleusercontent.com';
  }
  
  static String get googleIosClientId {
    return '845113946067-hvg4pfb2ncjicg8mh8en5ouckugkdbeh.apps.googleusercontent.com';
  }
  
  static String get apiBaseUrl {
    return 'http://34.128.76.161:3000/api/v1';
  }
}