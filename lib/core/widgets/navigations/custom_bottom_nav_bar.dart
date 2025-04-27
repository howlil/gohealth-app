import 'package:flutter/material.dart';
import 'nav_items.dart';
import '../../../configs/routes.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTabChanged;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Get bottom padding for safe area
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        height: 56,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 35, 35, 35),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
             NavItems(
              icon: Icons.home_outlined,
              iconSelected: Icons.home,
              isSelected: currentIndex == 0,
              onTap: () => _handleTabChange(context, 0),
            ),
            NavItems(
              icon: Icons.add_circle_outline,
              iconSelected: Icons.add_circle,
              isSelected: currentIndex == 1,
              onTap: () => _handleTabChange(context, 1),
            ),
            NavItems(
              icon: Icons.person_outline,
              iconSelected: Icons.person,
              isSelected: currentIndex == 2,
              onTap: () => _handleTabChange(context, 2),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle tab change and call the callback if provided
  void _handleTabChange(BuildContext context, int index) {
    if (currentIndex == index) return; // Don't navigate if already on this tab

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
    Navigator.of(context).pushReplacementNamed(route);

    // Also call the onTabChanged callback if provided (for backward compatibility)
    if (onTabChanged != null) {
      onTabChanged!(index);
    }
  }
}
