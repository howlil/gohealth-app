import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/splash_screen.dart';
import 'configs/routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GoHealth',
      theme: ThemeData(
        primaryColor: const Color(0xFF2ECC71),
        fontFamily: 'Poppins',
      ),
      home: const SplashScreen(),
      onGenerateRoute: AppRoutes.generateRoute,
      initialRoute: AppRoutes.splash,
    );
  }
}
