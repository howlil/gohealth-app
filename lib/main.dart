import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'configs/router_config.dart';
import 'core/utils/app_colors.dart';

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
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'GoHealth',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        fontFamily: 'Poppins',
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
    );
  }
}