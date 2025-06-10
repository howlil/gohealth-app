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
  final String? category;
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
    this.category,
    this.isFavorite = false,
    this.description,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'] as String,
      name: json['name'] as String,
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      servingSize: json['servingSize'] as String?,
      servingUnit: json['servingUnit'] as String?,
      weight:
          json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      nutrients: json['nutrients'] != null
          ? Map<String, double>.from(json['nutrients'] as Map)
          : null,
      vitamins: json['vitamins'] != null
          ? Map<String, double>.from(json['vitamins'] as Map)
          : null,
      category: json['category'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'imageUrl': imageUrl,
      'servingSize': servingSize,
      'servingUnit': servingUnit,
      'weight': weight,
      'nutrients': nutrients,
      'vitamins': vitamins,
      'category': category,
      'isFavorite': isFavorite,
      'description': description,
    };
  }
}
