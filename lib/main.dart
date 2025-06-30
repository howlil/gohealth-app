import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('🚀 Memulai inisialisasi aplikasi GoHealth...');

    // Set orientasi yang diizinkan
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    debugPrint('✅ Orientasi layar dikonfigurasi');

    // Load environment variables PERTAMA
    debugPrint('🔧 Memuat environment variables...');
    await dotenv.load(fileName: ".env");
    debugPrint('✅ Environment variables berhasil dimuat');

    // Initialize Firebase KEDUA
    debugPrint('🔥 Inisialisasi Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase berhasil diinisialisasi');

    // Register background message handler SETELAH Firebase diinisialisasi
    debugPrint('📱 Mendaftarkan background message handler...');
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    debugPrint('✅ Background message handler terdaftar');

    // Initialize local database KETIGA (simplified)
    debugPrint('🗄️ Inisialisasi database lokal...');
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.database;
      debugPrint('✅ Database lokal berhasil diinisialisasi');
    } catch (e) {
      debugPrint('⚠️ Database initialization warning: $e');
      // Continue even if database fails
    }

    debugPrint('🎉 Core services berhasil diinisialisasi!');
  } catch (e, stackTrace) {
    debugPrint('❌ Error during app initialization: $e');
    debugPrint('❌ Stack trace: $stackTrace');
    // Continue to run app even if some initialization fails
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Delayed initialization untuk services yang berat
    _initializeHeavyServices();
  }

  Future<void> _initializeHeavyServices() async {
    // Delay untuk memastikan UI sudah ter-render
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    try {
      // Initialize FCM service secara background tanpa mengganggu UI
      debugPrint('📱 Background initialization FCM service...');
      final fcmService = FCMService();

      // Non-blocking FCM initialization
      fcmService.initialize().catchError((error) {
        debugPrint('⚠️ FCM initialization error (non-blocking): $error');
      });

      setState(() {
        _isInitialized = true;
      });

      debugPrint('✅ Heavy services initialized in background');
    } catch (e) {
      debugPrint('⚠️ Heavy services initialization warning: $e');
      // Set initialized anyway to not block UI
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

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

  @override
  void dispose() {
    // Cleanup jika diperlukan
    super.dispose();
  }
}
