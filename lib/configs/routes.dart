import 'package:flutter/material.dart';
import '../features/splash_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';



class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String ibm = '/ibm';
  static const String food = '/food';
  static const String profile = '/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
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