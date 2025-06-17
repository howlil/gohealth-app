import '../models/food_model.dart';

class Meal {
  final String id;
  final String userId;
  final String foodId;
  final String mealType;
  final String date;
  final double quantity;
  final String unit;
  final double totalCalories;
  final double totalProtein;
  final double totalFat;
  final double totalCarbs;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Food? food;

  Meal({
    required this.id,
    required this.userId,
    required this.foodId,
    required this.mealType,
    required this.date,
    required this.quantity,
    required this.unit,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalFat,
    required this.totalCarbs,
    required this.createdAt,
    required this.updatedAt,
    this.food,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(String? dateStr) {
      if (dateStr == null) return DateTime.now();

      // Check if the date is in DD-MM-YYYY format
      if (dateStr.contains('-') && dateStr.split('-').length == 3) {
        try {
          final parts = dateStr.split('-');
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
        } catch (e) {
          print('Error parsing date: $dateStr, $e');
        }
      }

      // Try standard ISO format as fallback
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        print('Error parsing ISO date: $dateStr, $e');
        return DateTime.now();
      }
    }

    return Meal(
      id: json['id'] as String,
      userId: json['userId'] as String,
      foodId: json['foodId'] as String,
      mealType: json['mealType'] as String,
      date: json['date'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      totalCalories: (json['totalCalories'] as num).toDouble(),
      totalProtein: (json['totalProtein'] as num).toDouble(),
      totalFat: (json['totalFat'] as num).toDouble(),
      totalCarbs: (json['totalCarbs'] as num).toDouble(),
      createdAt: parseDate(json['createdAt']?.toString()),
      updatedAt: parseDate(json['updatedAt']?.toString()),
      food: json['food'] != null
          ? Food.fromJson(json['food'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    String formatDate(DateTime date) {
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    }

    return {
      'id': id,
      'userId': userId,
      'foodId': foodId,
      'mealType': mealType,
      'date': date,
      'quantity': quantity,
      'unit': unit,
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalFat': totalFat,
      'totalCarbs': totalCarbs,
      'createdAt': formatDate(createdAt),
      'updatedAt': formatDate(updatedAt),
      if (food != null) 'food': food!.toJson(),
    };
  }
}

class DailyMealSummary {
  final String date;
  final double totalCalories;
  final double totalProtein;
  final double totalFat;
  final double totalCarbs;
  final Map<String, List<Meal>> mealsByType;

  DailyMealSummary({
    required this.date,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalFat,
    required this.totalCarbs,
    required this.mealsByType,
  });

  factory DailyMealSummary.fromJson(Map<String, dynamic> json) {
    final mealsByType = <String, List<Meal>>{};

    if (json['mealsByType'] != null) {
      (json['mealsByType'] as Map<String, dynamic>).forEach((key, value) {
        mealsByType[key] = (value as List)
            .map((meal) => Meal.fromJson(meal as Map<String, dynamic>))
            .toList();
      });
    }

    return DailyMealSummary(
      date: json['date'] as String,
      totalCalories: (json['totalCalories'] as num).toDouble(),
      totalProtein: (json['totalProtein'] as num).toDouble(),
      totalFat: (json['totalFat'] as num).toDouble(),
      totalCarbs: (json['totalCarbs'] as num).toDouble(),
      mealsByType: mealsByType,
    );
  }
}
