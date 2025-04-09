import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/layouts/app_layout.dart';
import '../../../core/utils/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import 'widgets/food_item.dart';
import 'widgets/nutrient_bar.dart';
import '../../core/widgets/round_search_field.dart';
import 'widgets/tab_selector.dart';
import 'models/food_model.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedTab = 'Semua';
  Food? _selectedFood;

  final List<String> _tabs = ['Semua', 'Buah-buahan', 'Sayuran', 'Favorit'];

  // Dummy data untuk daftar makanan
  final List<Food> _foods = [
    Food(
      name: 'Apel',
      calories: 52,
      weight: '100g',
      nutrients: {
        'Karbohidrat': 13.8,
        'Protein': 0.3,
        'Lemak': 0.2,
        'Serat': 2.4,
      },
      vitamins: {
        'Vitamin C': {'value': 8.0, 'percentage': 9},
        'Vitamin K': {'value': 2.2, 'percentage': 85},
        'Vitamin A': {'value': 3.0, 'percentage': 71},
      },
      imageUrl: null,
      category: 'Buah-buahan',
      isFavorite: false,
      description:
          'Buah apel mengandung serat yang tinggi dan dapat membantu menjaga kesehatan pencernaan, serta kaya antioksidan yang memiliki sifat anti-kanker dan anti-inflamasi.',
    ),
    Food(
      name: 'Pisang',
      calories: 89,
      weight: '100g',
      nutrients: {
        'Karbohidrat': 22.8,
        'Protein': 1.1,
        'Lemak': 0.3,
        'Serat': 2.6,
      },
      vitamins: {},
      imageUrl: null,
      category: 'Buah-buahan',
      isFavorite: false,
      description:
          'Pisang kaya akan potasium dan vitamin B6 yang membantu fungsi jantung dan sistem saraf.',
    ),
    Food(
      name: 'Brokoli',
      calories: 55,
      weight: '100g',
      nutrients: {
        'Karbohidrat': 11.2,
        'Protein': 2.8,
        'Lemak': 0.4,
        'Serat': 2.6,
      },
      vitamins: {
        'Vitamin C': {'value': 89.2, 'percentage': 99},
        'Vitamin K': {'value': 102, 'percentage': 85},
        'Vitamin A': {'value': 31, 'percentage': 71},
      },
      imageUrl: null,
      category: 'Sayuran',
      isFavorite: true,
      description:
          'Brokoli adalah sayuran yang kaya vitamin C, vitamin K dan serat. Sayuran yang mengandung sulforaphane, senyawa yang memiliki sifat anti-kanker dan anti-inflamasi.',
    ),
    Food(
      name: 'Dada Ayam',
      calories: 165,
      weight: '100g',
      nutrients: {
        'Karbohidrat': 0.0,
        'Protein': 31.0,
        'Lemak': 3.6,
        'Serat': 0.0,
      },
      vitamins: {},
      imageUrl: null,
      category: 'Protein',
      isFavorite: false,
      description:
          'Dada ayam adalah sumber protein berkualitas tinggi dengan kandungan lemak yang rendah.',
    ),
    Food(
      name: 'Nasi Merah',
      calories: 111,
      weight: '100g',
      nutrients: {
        'Karbohidrat': 23.5,
        'Protein': 2.6,
        'Lemak': 0.9,
        'Serat': 1.8,
      },
      vitamins: {},
      imageUrl: null,
      category: 'Karbohidrat',
      isFavorite: false,
      description:
          'Nasi merah kaya akan serat dan nutrisi, serta memiliki indeks glikemik yang lebih rendah dibanding nasi putih.',
    ),
    Food(
      name: 'Susu Rendah Lemak',
      calories: 42,
      weight: '100g',
      nutrients: {
        'Karbohidrat': 5.0,
        'Protein': 3.5,
        'Lemak': 1.0,
        'Serat': 0.0,
      },
      vitamins: {},
      imageUrl: null,
      category: 'Minuman',
      isFavorite: false,
      description:
          'Susu rendah lemak menyediakan kalsium dan protein tanpa lemak jenuh yang tinggi.',
    ),
  ];

  List<Food> get _filteredFoods {
    var filteredList = _foods;

    // Filter berdasarkan tab yang dipilih
    if (_selectedTab == 'Favorit') {
      filteredList = filteredList.where((food) => food.isFavorite).toList();
    } else if (_selectedTab != 'Semua') {
      filteredList =
          filteredList.where((food) => food.category == _selectedTab).toList();
    }

    // Filter berdasarkan pencarian
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filteredList =
          filteredList
              .where((food) => food.name.toLowerCase().contains(query))
              .toList();
    }

    return filteredList;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Database Makanan Sehat',
      backgroundColor: const Color(0xFFF8F9FA),
      showBackButton: true,
      child: Stack(
        children: [
          // Background gradient bubbles
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            left: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.05),
              ),
            ),
          ),

          // Main content
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildHeader(),
                    const SizedBox(height: 16),
                    RoundSearchField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    TabSelector(
                      tabs: _tabs,
                      selectedTab: _selectedTab,
                      onTabSelected: (tab) {
                        setState(() {
                          _selectedTab = tab;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Daftar makanan dan detail
              Expanded(
                child:
                    _selectedFood == null
                        ? _buildFoodList()
                        : _buildFoodDetails(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Cari Makanan',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildFoodList() {
    return _filteredFoods.isEmpty
        ? Center(
          child: Text(
            'Tidak ada makanan yang ditemukan',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        )
        : ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: _filteredFoods.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final food = _filteredFoods[index];
            return FoodItem(
              food: food,
              onTap: () {
                setState(() {
                  _selectedFood = food;
                });
              },
              onFavoriteToggle: () {
                setState(() {
                  food.isFavorite = !food.isFavorite;
                });
              },
            );
          },
        );
  }

  Widget _buildFoodDetails() {
    final food = _selectedFood!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      food.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFood = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${food.calories} kcal per ${food.weight}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Informasi Nutrisi (per 100g)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNutrientValue('Kalori', '${food.calories} kcal'),
                  ],
                ),
                const SizedBox(height: 12),

                NutrientBar(
                  label: 'Karbohidrat',
                  value: food.nutrients['Karbohidrat'] ?? 0,
                  unit: 'g',
                  color: AppColors.primary,
                  maxValue: 30,
                ),
                const SizedBox(height: 10),

                NutrientBar(
                  label: 'Protein',
                  value: food.nutrients['Protein'] ?? 0,
                  unit: 'g',
                  color: AppColors.secondary,
                  maxValue: 10,
                ),
                const SizedBox(height: 10),

                NutrientBar(
                  label: 'Lemak',
                  value: food.nutrients['Lemak'] ?? 0,
                  unit: 'g',
                  color: Colors.orange,
                  maxValue: 10,
                ),
                const SizedBox(height: 10),

                NutrientBar(
                  label: 'Serat',
                  value: food.nutrients['Serat'] ?? 0,
                  unit: 'g',
                  color: Colors.purple,
                  maxValue: 5,
                ),

                if (food.vitamins.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Vitamin',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...food.vitamins.entries.map((entry) {
                    final vitaminName = entry.key;
                    final value = entry.value['value'] as double;
                    final percentage = entry.value['percentage'] as int;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: NutrientBar(
                        label: vitaminName,
                        value: value,
                        unit: 'mg',
                        percentage: percentage,
                        color: AppColors.accent1,
                        maxValue: 150,
                      ),
                    );
                  }).toList(),
                ],

                const SizedBox(height: 24),
                if (food.description.isNotEmpty)
                  Text(
                    food.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tombol tambahkan ke menu
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                // Implementasi untuk menambahkan ke menu
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${food.name} ditambahkan ke menu harian Anda',
                    ),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Tambahkan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildNutrientValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
