import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'custom_bottom_nav_bar.dart';
import 'custom_sidebar.dart';
import 'responsive_layout.dart';
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
        child: showBottomNavBar
            ? Row(
                children: [
                  // Compact sidebar for landscape mobile
                  _buildCompactSidebar(context),
                  // Main content with proper scrolling
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height -
                              kToolbarHeight -
                              MediaQuery.of(context).padding.top -
                              MediaQuery.of(context).padding.bottom,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: child,
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: child,
                ),
              ),
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }

  // New compact sidebar widget for mobile landscape
  Widget _buildCompactSidebar(BuildContext context) {
    return Container(
      width: 48, // Reduced from 56 to 48
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(1, 0),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                kToolbarHeight -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
          ),
          child: IntrinsicHeight(
            child: Column(
              children: [
                const SizedBox(height: 4),
                // Logo icon - smaller
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                // Navigation items
                _buildCompactNavItem(
                  context: context,
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  route: '/home',
                  isSelected: currentIndex == 0,
                ),
                _buildCompactNavItem(
                  context: context,
                  icon: Icons.add_circle_outline,
                  selectedIcon: Icons.add_circle,
                  route: '/nutrition',
                  isSelected: currentIndex == 1,
                ),
                _buildCompactNavItem(
                  context: context,
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  route: '/profile',
                  isSelected: currentIndex == 2,
                ),
                const Spacer(),
                // Additional options
                _buildCompactNavItem(
                  context: context,
                  icon: Icons.monitor_weight_outlined,
                  selectedIcon: Icons.monitor_weight,
                  route: '/bmi',
                  isSelected: false,
                  isSecondary: true,
                ),
                _buildCompactNavItem(
                  context: context,
                  icon: Icons.restaurant_outlined,
                  selectedIcon: Icons.restaurant,
                  route: '/food',
                  isSelected: false,
                  isSecondary: true,
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String route,
    required bool isSelected,
    bool isSecondary = false,
  }) {
    return Container(
      width: 48,
      height: isSecondary ? 32 : 36, // Reduced heights
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNavigation(context, route),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.green.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected
                    ? Colors.green
                    : (isSecondary
                        ? Colors.grey.shade500
                        : Colors.grey.shade700),
                size: isSecondary ? 16 : 18, // Reduced icon sizes
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, String route) {
    if (Navigator.of(context).userGestureInProgress) return;
    context.go(route);
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
