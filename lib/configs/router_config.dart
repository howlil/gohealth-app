import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/splash_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/foods/food_screen.dart';
import '../features/ibm/ibm_screen.dart';
import '../features/nutrition/daily_nutrition_tracker_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = 
      GlobalKey<NavigatorState>(debugLabel: 'root');
  
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // Splash screen
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Main screens
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
      
      // Detail screens
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