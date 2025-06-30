import 'package:go_router/go_router.dart';
import 'package:gohealth/screens/login_screen.dart';
import 'package:gohealth/providers/auth_provider.dart';
import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/food_screen.dart';
import '../screens/ibm_screen.dart';
import '../screens/daily_nutrition_tracker_screen.dart';
import '../screens/registration_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/activity_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/login', // Langsung ke login tanpa splash
      redirect: (context, state) {
        final isLoggedIn = authProvider.isLoggedIn;
        final isLoading = authProvider.isLoading;
        final currentLocation = state.matchedLocation;

        debugPrint(
            'Router redirect - isLoggedIn: $isLoggedIn, isLoading: $isLoading, location: $currentLocation');

        // Don't redirect while loading, stay on current page
        if (isLoading) {
          debugPrint('Auth loading, staying on: $currentLocation');
          return null;
        }

        // If logged in and on auth screens, redirect to home
        if (isLoggedIn &&
            (currentLocation == '/login' || currentLocation == '/register')) {
          debugPrint(
              'User logged in, redirecting to home from: $currentLocation');
          return '/home';
        }

        // If not logged in and not on auth screens, redirect to login
        if (!isLoggedIn &&
            currentLocation != '/login' &&
            currentLocation != '/register') {
          debugPrint('Redirecting to login from: $currentLocation');
          return '/login';
        }

        debugPrint('No redirect needed for: $currentLocation');
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const LoginScreen(), // Redirect ke login
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegistrationScreen(),
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
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/food',
          builder: (context, state) => const FoodScreen(),
        ),
        GoRoute(
          path: '/bmi',
          builder: (context, state) => const IBMScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/activity',
          builder: (context, state) => const ActivityScreen(),
        ),
      ],
    );
  }
}
