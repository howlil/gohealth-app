import 'package:flutter/material.dart';
import '../widgets/navigations/custom_bottom_nav_bar.dart';
import 'package:go_router/go_router.dart';

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
        leading:
            showBackButton
                ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Color(0xFF2ECC71),
                  ),
                  onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    try {
                      context.pop();
                    } catch (e) {
                      context.go('/home');
                    }
                  }
                },
              )
                : null,
        actions: actions,
      ),

      // Content Area
      body: SafeArea(
        bottom: false, // Karena bottom bar custom
        child: child,
      ),

      bottomNavigationBar:
          showBottomNavBar
              ? CustomBottomNavBar(currentIndex: currentIndex)
              : null,
      // Optional Floating Action Button
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}
