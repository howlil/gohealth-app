import 'meal_type.dart';

class FoodEntry {
  final String name;
  final int calories;
  final MealType mealType;
  final DateTime timestamp;
  final Map<String, double>? nutrients;
  
  FoodEntry({
    required this.name,
    required this.calories,
    required this.mealType,
    required this.timestamp,
    this.nutrients,
  });
}