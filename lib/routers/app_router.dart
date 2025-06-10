import 'package:go_router/go_router.dart';
import 'package:gohealth/screens/login_screen.dart';
import 'package:gohealth/providers/auth_provider.dart';
import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/food_screen.dart';
import '../screens/ibm_screen.dart';
import '../screens/daily_nutrition_tracker_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final isLoggedIn = authProvider.isLoggedIn;
        final isGoingToLogin = state.matchedLocation == '/login';
        final isGoingToSplash = state.matchedLocation == '/';

        // Don't redirect if going to splash screen
        if (isGoingToSplash) {
          return null;
        }

        // Handle auth redirects
        if (!isLoggedIn && !isGoingToLogin) {
          return '/login';
        }
        if (isLoggedIn && isGoingToLogin) {
          return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen() as Widget,
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen() as Widget,
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/nutrition',
          builder: (context, state) => const DailyNutritionTrackerScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen() as Widget,
        ),
        GoRoute(
          path: '/food',
          builder: (context, state) => const FoodScreen(),
        ),
        GoRoute(
          path: '/ibm',
          builder: (context, state) => const IBMScreen(),
        ),
      ],
    );
  }
}
