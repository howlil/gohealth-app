import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class NavItems extends StatelessWidget {
  final IconData icon;
  final IconData iconSelected;
  final bool isSelected;
  final VoidCallback onTap;

  const NavItems({
    super.key,
    required this.icon,
    required this.iconSelected,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        height: 56,
        child: Center(
          child: Icon(
            isSelected ? iconSelected : icon,
            color: isSelected ? AppColors.primary : Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
