class Food {
  final String name;
  final int calories;
  final String weight;
  final Map<String, double> nutrients;
  final Map<String, Map<String, dynamic>> vitamins;
  final String? imageUrl;
  final String category;
  bool isFavorite;
  final String description;

  Food({
    required this.name,
    required this.calories,
    required this.weight,
    required this.nutrients,
    required this.vitamins,
    this.imageUrl,
    required this.category,
    required this.isFavorite,
    required this.description,
  });
}