import 'package:flutter/material.dart';
import '../../../features/foods/models/food_model.dart';

class FoodSearchResult extends StatelessWidget {
  final Food food;
  final VoidCallback onTap;

  const FoodSearchResult({
    super.key,
    required this.food,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        food.name,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${food.calories} kcal per ${food.weight}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: const Icon(
        Icons.add_circle_outline,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}