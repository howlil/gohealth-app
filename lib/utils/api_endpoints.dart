class ApiEndpoints {
  static const String baseUrl = '/api';
  static const String auth = '/auth';
  static const String users = '/api/users';
  static const String bmi = '/api/bmi';
  static const String profile = '/profile';
  static const String dashboard = '/api/users/dashboard';
  static const String health = '/health';
  static const String exercise = '/exercise';
  static const String nutrition = '/nutrition';
  static const String water = '/water';
  static const String sleep = '/sleep';
  static const String weight = '/weight';
  static const String goal = '/goal';
  static const String notification = '/notification';
  static const String setting = '/setting';
  
  // User endpoints
  static const String me = '$baseUrl$auth/me';
  static const String updateProfile = '$users/profile';
  static const String uploadProfileImage = '$users/profile/image';
  
  // Activity endpoints
  static const String activities = '$baseUrl$exercise/activities';
}