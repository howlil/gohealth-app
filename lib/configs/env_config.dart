import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      // .env file might not exist in production
      print('Warning: .env file not found. Using environment variables or build config.');
    }
  }
  
  static String get googleWebClientId {
    return dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? 
           const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', 
               defaultValue: 'GOOGLE_WEB_CLIENT_ID_NOT_SET');
  }
  
  static String get googleAndroidClientId {
    return dotenv.env['GOOGLE_ANDROID_CLIENT_ID'] ?? 
           const String.fromEnvironment('GOOGLE_ANDROID_CLIENT_ID',
               defaultValue: 'GOOGLE_ANDROID_CLIENT_ID_NOT_SET');
  }
  
  static String get googleIosClientId {
    return dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? 
           const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID',
               defaultValue: 'GOOGLE_IOS_CLIENT_ID_NOT_SET');
  }
  
  static String get apiBaseUrl {
    return dotenv.env['API_BASE_URL'] ?? 
           const String.fromEnvironment('API_BASE_URL',
               defaultValue: 'http://34.101.52.148:3000');
  }
}