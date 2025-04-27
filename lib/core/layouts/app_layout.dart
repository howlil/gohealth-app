import 'package:flutter/material.dart';
import '../widgets/navigations/custom_bottom_nav_bar.dart';
import '../../configs/routes.dart';

class AppLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final int currentIndex;
  final List<Widget>? actions;
  final bool showBackButton;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;
  final bool showBottomNavBar;

  const AppLayout({
    super.key,
    required this.child,
    this.title = 'GoHealth',
    this.currentIndex = 0,
    this.actions,
    this.showBackButton = false,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
    this.showBottomNavBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: backgroundColor ?? Colors.grey[50],
      // App Bar (Top Bar)
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF2ECC71),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: showBackButton,
        leading: showBackButton 
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Color(0xFF2ECC71),
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: actions,
      ),
      
      // Content Area
      body: SafeArea(
        bottom: false, // Karena bottom bar custom
        child: child,
      ),
      
      // Custom Bottom Navigation Bar
      bottomNavigationBar: showBottomNavBar 
          ? CustomBottomNavBar(
              currentIndex: currentIndex,
              onTabChanged: (index) => _navigateToTab(context, index),
            )
          : null,
      
      // Optional Floating Action Button
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }

  // Navigasi ke halaman sesuai dengan tab yang dipilih
  void _navigateToTab(BuildContext context, int index) {
    if (index == currentIndex) return; // Jika sudah di tab yang sama, tidak perlu navigasi
    
    String route;
    switch (index) {
      case 0:
        route = AppRoutes.home;
        break;
      case 1:
        route = AppRoutes.nutrition; 
        break;
      case 2:
        route = AppRoutes.profile;
        break;
      default:
        route = AppRoutes.home;
    }
  
    Navigator.of(context).pushNamedAndRemoveUntil(
      route, 
      (Route<dynamic> route) => false // Menghapus semua route sebelumnya dari stack
    );
  }
}