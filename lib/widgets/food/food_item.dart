import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/food_model.dart';

class FoodItem extends StatelessWidget {
  final Food food;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const FoodItem({
    super.key,
    required this.food,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Optional food image or icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: food.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              food.imageUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            _getCategoryIcon(food.category?.name ?? 'Umum'),
                            size: 20,
                            color: Colors.grey.shade700,
                          ),
                  ),
                  const SizedBox(width: 12),

                  // Food name and calories
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${food.calories.toStringAsFixed(0)} kcal per ${food.weight?.toStringAsFixed(0) ?? '100'}g',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (food.category != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            food.category!.name,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Favorite button
                  GestureDetector(
                    onTap: onFavoriteToggle,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        food.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 20,
                        color: food.isFavorite
                            ? Colors.red.shade400
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'buah':
      case 'buah-buahan':
        return Icons.apple;
      case 'sayuran':
        return Icons.eco;
      case 'daging':
      case 'protein':
        return Icons.egg;
      case 'karbohidrat':
      case 'beras & sereal':
        return Icons.rice_bowl;
      case 'minuman':
        return Icons.local_drink;
      case 'keju & susu':
        return Icons.local_drink;
      case 'ikan & seafood':
        return Icons.set_meal;
      case 'kacang-kacangan':
        return Icons.grain;
      default:
        return Icons.food_bank;
    }
  }
}
