import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class CustomSegmentedControl extends StatelessWidget {
  final List<String> tabs;
  final String activeTab;
  final Function(String) onTabSelected;

  const CustomSegmentedControl({
    super.key,
    required this.tabs,
    required this.activeTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: tabs.map((tab) => _buildTabItem(tab, context)).toList(),
      ),
    );
  }

  Widget _buildTabItem(String tab, BuildContext context) {
    final isActive = activeTab == tab;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(tab),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Center(
            child: Text(
              tab,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade700,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}