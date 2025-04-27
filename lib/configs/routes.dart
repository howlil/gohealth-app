import 'package:flutter/material.dart';
import '../features/splash_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/foods/food_screen.dart';
import '../features/ibm/ibm_screen.dart';
import '../features/nutrition/daily_nutrition_tracker_screen.dart';



class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String ibm = '/ibm';
  static const String nutrition = '/nutrition';
  static const String food = '/food';
  static const String profile = '/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case ibm:
        return MaterialPageRoute(builder: (_) => const IBMScreen());
      case nutrition:
        return MaterialPageRoute(builder: (_) => const DailyNutritionTrackerScreen());
      case food:
        return MaterialPageRoute(builder: (_) => const FoodScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route tidak ditemukan: ${settings.name}'),
            ),
          ),
        );
    }
  }
}