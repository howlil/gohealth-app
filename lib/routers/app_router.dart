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
import '../screens/registration_screen.dart';
import '../screens/notifications_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final isLoggedIn = authProvider.isLoggedIn;
        final isLoading = authProvider.isLoading;
        final currentLocation = state.matchedLocation;

        // Debug logging
        debugPrint(
            'Router redirect - isLoggedIn: $isLoggedIn, isLoading: $isLoading, location: $currentLocation');

        // Allow splash screen ketika masih loading initial check
        if (currentLocation == '/' && isLoading) {
          debugPrint('Showing splash screen while loading');
          return null;
        }

        // Setelah loading selesai dari splash, redirect ke home/login
        if (currentLocation == '/' && !isLoading) {
          final redirectTo = isLoggedIn ? '/home' : '/login';
          debugPrint('Splash finished, redirecting to: $redirectTo');
          return redirectTo;
        }

        // Jangan redirect jika sedang di login/register screen dan belum login
        // Biarkan user tetap di screen tersebut untuk melihat error/success message
        if (!isLoggedIn &&
            (currentLocation == '/login' || currentLocation == '/register')) {
          debugPrint('Staying on auth screen: $currentLocation');
          return null;
        }

        // Redirect ke login jika belum login dan bukan di auth screens
        if (!isLoggedIn &&
            currentLocation != '/login' &&
            currentLocation != '/register') {
          debugPrint('Redirecting to login from: $currentLocation');
          return '/login';
        }

        // Jika sudah login tapi masih di auth screens, redirect ke home
        // Tapi tambahkan delay untuk memberi kesempatan success dialog muncul
        if (isLoggedIn &&
            (currentLocation == '/login' || currentLocation == '/register')) {
          debugPrint(
              'User logged in, will redirect to home from: $currentLocation');
          // Return null dulu, biar screen handle navigation sendiri
          return null;
        }

        debugPrint('No redirect needed for: $currentLocation');
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
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
      ],
    );
  }
}
