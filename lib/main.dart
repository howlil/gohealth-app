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
import 'package:gohealth/services/notification_manager.dart';
import 'package:gohealth/services/fcm_service.dart';
import 'package:gohealth/widgets/app_loading_wrapper.dart';
import 'package:gohealth/dao/database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow all orientations (portrait and landscape)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up background message handler BEFORE initializing other services
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize local database
  try {
    final dbHelper = DatabaseHelper();
    await dbHelper.database; // Initialize database
    debugPrint('Local SQLite database initialized successfully');
  } catch (e) {
    debugPrint('Error initializing database: $e');
  }

  // Initialize notification services
  await NotificationManager.instance.initialize();

  // Setup FCM listeners untuk handle semua state
  await _setupFCMListeners();

  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

// Setup FCM listeners untuk handle semua state aplikasi
Future<void> _setupFCMListeners() async {
  final fcmService = FCMService();

  // Initialize FCM service
  await fcmService.initialize();

  // Configure listeners dengan callback yang tepat
  fcmService.configureFCMListeners(
    onMessage: (RemoteMessage message) {
      // Local notification sudah di-handle di FCMService
    },
    onMessageOpenedApp: (RemoteMessage message) {
      // Handle navigation akan diimplementasikan sesuai kebutuhan aplikasi
    },
  );
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
