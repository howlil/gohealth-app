import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';

class AppLoadingWrapper extends StatelessWidget {
  final Widget child;

  const AppLoadingWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Tampilkan splash screen selama auth provider masih loading
        if (authProvider.isLoading) {
          // Return MaterialApp wrapper untuk SplashScreen agar memiliki Directionality
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
              useMaterial3: false,
              primarySwatch: Colors.green,
              primaryColor: Colors.green,
            ),
            home: const SplashScreen(),
          );
        }

        // Jika sudah selesai loading, tampilkan child (app dengan router)
        return child;
      },
    );
  }
}
