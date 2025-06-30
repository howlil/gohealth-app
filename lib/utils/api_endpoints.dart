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
  static const String meals = '/api/meals';
  static const String water = '/water';
  static const String sleep = '/sleep';
  static const String weight = '/weight';
  static const String goal = '/goal';
  static const String notification = '/notification';
  static const String setting = '/setting';

  // Auth endpoints - coba struktur yang lebih sederhana
  static const String login = '/auth/login'; // Hapus /api prefix
  static const String register = '/auth/register'; // Hapus /api prefix
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Alternative endpoints jika yang atas tidak work
  static const String loginAlt = '/api/auth/login';
  static const String registerAlt = '/api/auth/register';

  // User endpoints
  static const String me = '$baseUrl$auth/me';
  static const String updateProfile = '$users/profile';
  static const String uploadProfileImage = '$users/profile/image';

  // Activity endpoints
  static const String activities = '$baseUrl$exercise/activities';

  // Meal endpoints
  static const String foods = '$meals/foods';
  static const String foodCategories = '$meals/foods/categories';
  static const String foodAutocomplete = '$meals/foods/autocomplete';
  static const String favorites = '$meals/favorites';

  // Notification endpoints
  static const String notifications = '/api/notifications';
  static const String notificationsUnreadCount = '$notifications/unread-count';
  static const String notificationsReadAll = '$notifications/read-all';
}
