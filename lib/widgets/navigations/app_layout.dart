import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'custom_bottom_nav_bar.dart';
import 'custom_sidebar.dart';
import '../../utils/responsive_helper.dart';

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
  final PreferredSizeWidget? bottom;

  const AppLayout({
    Key? key,
    required this.child,
    required this.title,
    this.currentIndex = 0,
    this.actions,
    this.showBackButton = true,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
    this.showBottomNavBar = true,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      builder: (context, constraints) {
        final isLandscape = ResponsiveHelper.isLandscape(context);
        final isMobile = ResponsiveHelper.isMobile(context);
        final isTablet = ResponsiveHelper.isTablet(context);
        final isDesktop = ResponsiveHelper.isDesktop(context);

        // Untuk mobile dalam landscape mode, gunakan layout yang berbeda
        if (isMobile && isLandscape) {
          return _buildMobileLandscapeLayout(context);
        }

        // Gunakan layout sesuai ukuran layar
        if (isDesktop) {
          return _buildDesktopLayout(context);
        } else if (isTablet) {
          return _buildTabletLayout(context);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: backgroundColor ?? Colors.white,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                onPressed: () => _handleBackNavigation(context),
              )
            : null,
        actions: actions,
        bottom: bottom,
      ),
      body: SafeArea(
        bottom: false,
        child: child,
      ),
      bottomNavigationBar: showBottomNavBar
          ? CustomBottomNavBar(currentIndex: currentIndex)
          : null,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? const Color(0xFFF8F9FA),
      body: Row(
        children: [
          if (showBottomNavBar) CustomSidebar(currentIndex: currentIndex),
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                centerTitle: false,
                elevation: 0,
                backgroundColor: Colors.transparent,
                leading: showBackButton && !showBottomNavBar
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.black87),
                        onPressed: () => _handleBackNavigation(context),
                      )
                    : null,
                automaticallyImplyLeading: showBackButton && !showBottomNavBar,
                actions: [
                  ...?actions,
                  const SizedBox(width: 24),
                ],
                bottom: bottom,
              ),
              body: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: child,
              ),
              floatingActionButton: floatingActionButton,
              floatingActionButtonLocation: floatingActionButtonLocation,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? const Color(0xFFF8F9FA),
      body: Row(
        children: [
          if (showBottomNavBar) CustomSidebar(currentIndex: currentIndex),
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                centerTitle: false,
                elevation: 0,
                backgroundColor: Colors.transparent,
                leading: showBackButton && !showBottomNavBar
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.black87),
                        onPressed: () => _handleBackNavigation(context),
                      )
                    : null,
                automaticallyImplyLeading: showBackButton && !showBottomNavBar,
                actions: [
                  ...?actions,
                  const SizedBox(width: 16),
                ],
                bottom: bottom,
              ),
              body: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: child,
              ),
              floatingActionButton: floatingActionButton,
              floatingActionButtonLocation: floatingActionButtonLocation,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLandscapeLayout(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: backgroundColor ?? Colors.white,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 48, // Reduced height for landscape
        leading: showBackButton
            ? IconButton(
                iconSize: 20,
                icon: const Icon(Icons.arrow_back_ios,
                    color: Colors.black87, size: 18),
                onPressed: () => _handleBackNavigation(context),
              )
            : null,
        actions: actions?.map((action) {
          // Reduce icon size in actions
          if (action is IconButton) {
            return IconButton(
              iconSize: 20,
              icon: action.icon,
              onPressed: action.onPressed,
            );
          }
          return action;
        }).toList(),
        bottom: bottom,
      ),
      body: SafeArea(
        bottom: false,
        child: child,
      ),
      // Gunakan bottom navigation bar untuk mobile landscape
      bottomNavigationBar: showBottomNavBar
          ? CustomBottomNavBar(currentIndex: currentIndex)
          : null,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }


  void _handleBackNavigation(BuildContext context) {
    if (Navigator.of(context).userGestureInProgress) return;

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }
}
