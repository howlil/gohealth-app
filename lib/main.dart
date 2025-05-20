import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'configs/env_config.dart' show EnvConfig;
import 'configs/router_config.dart';
import 'core/utils/app_colors.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'features/auth/providers/auth_provider.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

   try {
    await EnvConfig.load();
  } catch (e) {
    debugPrint('Warning: Failed to load environment config: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider()..init(),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'GoHealth',
            theme: ThemeData(
              primaryColor: AppColors.primary,
              fontFamily: 'Poppins',
              useMaterial3: true,
            ),
            routerConfig: AppRouter.createRouter(authProvider),
          );
        },
      ),
    );
  }
}