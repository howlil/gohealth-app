import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';

class CustomSidebar extends StatelessWidget {
  final int currentIndex;

  const CustomSidebar({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          _buildLogo(),
          const SizedBox(height: 48),
          _buildNavItem(
            context: context,
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
            index: 0,
            route: '/home',
          ),
          _buildNavItem(
            context: context,
            icon: Icons.add_circle_outline,
            selectedIcon: Icons.add_circle,
            label: 'Nutrition Tracker',
            index: 1,
            route: '/nutrition',
          ),
          _buildNavItem(
            context: context,
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
            index: 2,
            route: '/profile',
          ),
          const Spacer(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                Icons.favorite,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'GoHealth',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required String route,
  }) {
    final isSelected = currentIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNavigation(context, route),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected ? AppColors.primary : Colors.grey.shade600,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color:
                        isSelected ? AppColors.primary : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, String route) {
    // Enhanced navigation protection
    if (!context.mounted) return;
    if (Navigator.of(context).userGestureInProgress) return;

    // Add debouncing to prevent rapid navigation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!context.mounted) return;

      try {
        context.go(route);
      } catch (e) {
        debugPrint('Sidebar navigation error: $e');
        // Fallback navigation
        Future.delayed(const Duration(milliseconds: 50), () {
          if (context.mounted) {
            try {
              context.go(route);
            } catch (e) {
              debugPrint('Sidebar fallback navigation also failed: $e');
            }
          }
        });
      }
    });
  }
}
