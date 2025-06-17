class FoodCategory {
  final String id;
  final String name;
  final String slug;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? foodCount;

  FoodCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.foodCount,
  });

  factory FoodCategory.fromJson(Map<String, dynamic> json) {
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

    return FoodCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String,
      createdAt: parseDate(json['createdAt']?.toString()),
      updatedAt: parseDate(json['updatedAt']?.toString()),
      foodCount: json['_count']?['foods'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    String formatDate(DateTime date) {
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    }

    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'createdAt': formatDate(createdAt),
      'updatedAt': formatDate(updatedAt),
      if (foodCount != null) '_count': {'foods': foodCount},
    };
  }
}

class Food {
  final String id;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? imageUrl;
  final String? servingSize;
  final String? servingUnit;
  final double? weight;
  final Map<String, double>? nutrients;
  final Map<String, double>? vitamins;
  final String? categoryId;
  final FoodCategory? category;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final String? description;

  Food({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.imageUrl,
    this.servingSize,
    this.servingUnit,
    this.weight,
    this.nutrients,
    this.vitamins,
    this.categoryId,
    this.category,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.description,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
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

    return Food(
      id: json['id'] as String,
      name: json['name'] as String,
      calories: (json['calory'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbohydrate'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      servingSize: json['servingSize'] as String?,
      servingUnit: json['servingUnit'] as String?,
      weight:
          json['weight'] != null ? (json['weight'] as num).toDouble() : 100.0,
      nutrients: {
        'Karbohidrat': (json['carbohydrate'] as num).toDouble(),
        'Protein': (json['protein'] as num).toDouble(),
        'Lemak': (json['fat'] as num).toDouble(),
      },
      vitamins: json['vitamins'] != null
          ? Map<String, double>.from(json['vitamins'] as Map)
          : null,
      categoryId: json['categoryId'] as String?,
      category: json['category'] != null
          ? FoodCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: parseDate(json['createdAt']?.toString()),
      updatedAt: parseDate(json['updatedAt']?.toString()),
      isFavorite: json['isFavorite'] as bool? ?? false,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    String formatDate(DateTime date) {
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    }

    return {
      'id': id,
      'name': name,
      'calory': calories,
      'protein': protein,
      'carbohydrate': carbs,
      'fat': fat,
      'imageUrl': imageUrl,
      'servingSize': servingSize,
      'servingUnit': servingUnit,
      'weight': weight,
      'nutrients': nutrients,
      'vitamins': vitamins,
      'categoryId': categoryId,
      'category': category?.toJson(),
      'isActive': isActive,
      'createdAt': formatDate(createdAt),
      'updatedAt': formatDate(updatedAt),
      'isFavorite': isFavorite,
      'description': description,
    };
  }

  Food copyWith({
    String? id,
    String? name,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? imageUrl,
    String? servingSize,
    String? servingUnit,
    double? weight,
    Map<String, double>? nutrients,
    Map<String, double>? vitamins,
    String? categoryId,
    FoodCategory? category,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    String? description,
  }) {
    return Food(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      imageUrl: imageUrl ?? this.imageUrl,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      weight: weight ?? this.weight,
      nutrients: nutrients ?? this.nutrients,
      vitamins: vitamins ?? this.vitamins,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      description: description ?? this.description,
    );
  }
}
