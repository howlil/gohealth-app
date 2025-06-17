import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class CategoryFilterChips extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final bool showFavoriteOption;

  const CategoryFilterChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.showFavoriteOption = true,
  });

  @override
  Widget build(BuildContext context) {
    final allCategories = [
      'Semua',
      ...categories,
      if (showFavoriteOption) 'Favorit',
    ];

    return Container(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allCategories.length,
        itemBuilder: (context, index) {
          final category = allCategories[index];
          final isSelected = category == selectedCategory;
          final isFavorite = category == 'Favorit';

          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 4,
              right: index == allCategories.length - 1 ? 0 : 4,
            ),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isFavorite) ...[
                    Icon(
                      Icons.favorite,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.red.shade400,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isFavorite
                              ? Colors.red.shade400
                              : Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => onCategorySelected(category),
              backgroundColor: Colors.white,
              selectedColor: isFavorite && isSelected
                  ? Colors.red.shade400
                  : AppColors.primary,
              checkmarkColor: Colors.white,
              showCheckmark: false,
              elevation: isSelected ? 3 : 0,
              pressElevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? (isFavorite ? Colors.red.shade400 : AppColors.primary)
                      : Colors.grey.shade300,
                  width: isSelected ? 0 : 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
