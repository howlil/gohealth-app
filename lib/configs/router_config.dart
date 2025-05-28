import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gohealth/features/auth/screens/login_screen.dart';
import 'package:gohealth/providers/auth_provider.dart';

import '../features/splash_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/foods/food_screen.dart';
import '../features/ibm/ibm_screen.dart';
import '../features/nutrition/daily_nutrition_tracker_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isGoingToLogin = state.matchedLocation == '/login';

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
        path: '/login',
        builder: (context, state) => const LoginScreen(),
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
        path: '/ibm',
        builder: (context, state) => const IBMScreen(),
      ),
    ],
  );
});

final router = routerProvider;
