class ApiEndpoints {
  // Auth Endpoints
  static const String auth = '/auth';
  static const String googleAuth = '$auth/google';
  static const String refreshToken = '$auth/refresh';
  static const String currentUser = '$auth/me';
  static const String logout = '$auth/logout';
  
  // User Endpoints
  static const String users = '/users';
  static const String userProfile = '$users/profile';
  static const String userDashboard = '$users/dashboard';
  static const String uploadProfileImage = '$users/profile/image';
  
  // Health Endpoints
  static const String bmi = '/bmi';
  static const String bmiHistory = '$bmi/history';
  static const String bmiLatest = '$bmi/latest';
  static const String bmiAnalysis = '$bmi/analysis';
  static const String bmiGoals = '$bmi/goals';
  static const String activeGoal = '$bmiGoals/active';
  
  // Meal Endpoints
  static const String meals = '/meals';
  static const String mealSummary = '$meals/summary';
  static const String searchFoods = '$meals/foods/search';
  static const String foodDetails = '$meals/foods';
  
  // Activity Endpoints
  static const String activities = '/activities';
  static const String activityTypes = '$activities/types';
  static const String activitySummary = '$activities/summary';
  
  // Utility method to build endpoint with ID
  static String withId(String endpoint, String id) => '$endpoint/$id';
}