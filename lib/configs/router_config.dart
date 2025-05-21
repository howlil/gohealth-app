import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/splash_screen.dart';
import '../features/home/home_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/foods/food_screen.dart';
import '../features/ibm/ibm_screen.dart';
import '../features/nutrition/daily_nutrition_tracker_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = 
      GlobalKey<NavigatorState>(debugLabel: 'root');
  
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: authProvider,
      redirect: (BuildContext context, GoRouterState state) {
        final isLoggedIn = authProvider.isLoggedIn;
        final isLoggingIn = state.uri.path == '/login';
        final isSplash = state.uri.path == '/';
        
        // If user is not logged in and trying to access protected routes
        if (!isLoggedIn && !isLoggingIn && !isSplash) {
          return '/login';
        }
        
        // If user is logged in and trying to access login page
        if (isLoggedIn && isLoggingIn) {
          return '/home';
        }
        
        return null; // No redirect
      },
      routes: [
        // Splash screen
        GoRoute(
          path: '/',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        
        // Login screen
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        
        // Main screens (protected routes)
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/nutrition',
          name: 'nutrition',
          builder: (context, state) => const DailyNutritionTrackerScreen(),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        
        // Detail screens (protected routes)
        GoRoute(
          path: '/food',
          name: 'food',
          builder: (context, state) => const FoodScreen(),
        ),
        GoRoute(
          path: '/ibm',
          name: 'ibm',
          builder: (context, state) => const IBMScreen(),
        ),
      ],
    );
  }
}