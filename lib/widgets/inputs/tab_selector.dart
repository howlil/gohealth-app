import 'package:flutter/material.dart';

class TabSelector extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? backgroundColor;

  const TabSelector({
    Key? key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.selectedColor,
    this.unselectedColor,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: List.generate(
          tabs.length,
          (index) => Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(index),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: selectedIndex == index
                      ? selectedColor ?? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: selectedIndex == index
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      color: selectedIndex == index
                          ? selectedColor ?? Colors.blue
                          : unselectedColor ?? Colors.grey[600],
                      fontWeight: selectedIndex == index
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
