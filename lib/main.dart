import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gohealth/routers/app_router.dart';
import 'package:provider/provider.dart';
import 'package:gohealth/providers/auth_provider.dart';
import 'package:gohealth/providers/profile_provider.dart';
import 'package:gohealth/providers/dashboard_provider.dart';
import 'package:gohealth/providers/notification_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gohealth/firebase_options.dart';
import 'package:gohealth/services/fcm_service.dart';
import 'package:gohealth/widgets/app_loading_wrapper.dart';
import 'package:gohealth/dao/database_helper.dart';
import 'package:gohealth/utils/env_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();



  // x`Allow all orientations (portrait and landscape)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  try {
    // Initialize Firebase
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');

    // Set up background message handler BEFORE initializing other services
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialize local database
    debugPrint('Initializing local database...');
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.database; // Initialize database
      debugPrint('Local database initialized successfully');
    } catch (e) {
      debugPrint('Error initializing database: $e');
    }

    // Initialize FCM service (single unified service)
    debugPrint('Initializing FCM service...');
    final fcmService = FCMService();
    await fcmService.initialize();
    debugPrint('FCM service initialized successfully');

    await dotenv.load(fileName: ".env");
    debugPrint('Environment loaded successfully');
  } catch (e) {
    debugPrint('Error during app initialization: $e');
  }

  debugPrint('=== GoHealth Started ===');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Builder(
        builder: (context) {
          final authProvider = Provider.of<AuthProvider>(context);
          final router = AppRouter.createRouter(authProvider);

          return AppLoadingWrapper(
            child: MaterialApp.router(
              title: 'GoHealth',
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
                useMaterial3: false,
                primarySwatch: Colors.green,
                primaryColor: Colors.green,
                textTheme: const TextTheme(
                  bodySmall: TextStyle(decoration: TextDecoration.none),
                  bodyMedium: TextStyle(decoration: TextDecoration.none),
                  bodyLarge: TextStyle(decoration: TextDecoration.none),
                ),
              ),
              routerConfig: router,
              debugShowCheckedModeBanner: false,
            ),
          );
        },
      ),
    );
  }
}
