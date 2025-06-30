import 'package:flutter/material.dart';
import '../widgets/navigations/app_layout.dart';
import '../utils/app_colors.dart';
import '../utils/responsive_helper.dart';
import '../widgets/glass_card.dart';
import '../widgets/food/food_item.dart';
import '../widgets/inputs/nutrient_bar.dart';
import '../widgets/inputs/modern_search_field.dart';
import '../widgets/inputs/category_filter_chips.dart';
import '../widgets/loading_skeleton.dart';
import '../models/food_model.dart';
import '../services/meal_service.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MealService _mealService = MealService();

  String _selectedTab = 'Semua';
  Food? _selectedFood;

  List<FoodCategory> _categories = [];
  List<Food> _foods = [];
  List<Food> _favoriteFoods = [];

  bool _isLoading = false;
  bool _isLoadingCategories = false;

  String? _errorMessage;

  int _currentPage = 1;
  bool _hasMoreData = true;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadCategories(),
      _loadFoods(refresh: true),
      _loadFavorites(),
    ]);
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final response = await _mealService.getFoodCategories();
      if (mounted &&
          response != null &&
          response.success &&
          response.data != null) {
        setState(() {
          _categories = response.data!;
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _loadFoods({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreData = true;
        _foods = [];
      });
    }

    if (!_hasMoreData || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? categorySlug;
      if (_selectedTab != 'Semua' && _selectedTab != 'Favorit') {
        final category = _categories.firstWhere(
          (cat) => cat.name == _selectedTab,
          orElse: () => _categories.first,
        );
        categorySlug = category.slug;
      }

      final response = await _mealService.getFoods(
        search:
            _searchController.text.isNotEmpty ? _searchController.text : null,
        category: categorySlug,
        page: _currentPage,
        limit: _pageSize,
      );

      if (mounted &&
          response != null &&
          response.success &&
          response.data != null) {
        final newFoods = response.data!['foods'] as List<Food>;

        // Sync favorite status with favorite list
        final syncedFoods = newFoods.map((food) {
          final isFavorite = _favoriteFoods.any((fav) => fav.id == food.id);
          return food.copyWith(isFavorite: isFavorite);
        }).toList();

        setState(() {
          if (refresh) {
            _foods = syncedFoods;
          } else {
            _foods.addAll(syncedFoods);
          }
          _hasMoreData = newFoods.length == _pageSize;
          _currentPage++;
        });
      } else {
        setState(() {
          _errorMessage = response?.message ?? 'Gagal memuat data makanan';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final response = await _mealService.getFavoriteFoods();
      if (mounted &&
          response != null &&
          response.success &&
          response.data != null) {
        setState(() {
          // Ensure all favorites have isFavorite = true
          _favoriteFoods = (response.data!['foods'] as List<Food>)
              .map((food) => food.copyWith(isFavorite: true))
              .toList();

          // Update main food list if already loaded
          if (_foods.isNotEmpty) {
            for (var i = 0; i < _foods.length; i++) {
              final isFavorite =
                  _favoriteFoods.any((fav) => fav.id == _foods[i].id);
              if (_foods[i].isFavorite != isFavorite) {
                _foods[i] = _foods[i].copyWith(isFavorite: isFavorite);
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> _toggleFavorite(Food food) async {
    try {
      if (food.isFavorite) {
        final response = await _mealService.removeFromFavorites(food.id);
        if (response != null && response.success) {
          setState(() {
            // Update the food in the main list
            final index = _foods.indexWhere((f) => f.id == food.id);
            if (index != -1) {
              _foods[index] = _foods[index].copyWith(isFavorite: false);
            }

            // Remove from favorites list
            _favoriteFoods.removeWhere((f) => f.id == food.id);

            // Update selected food if it's the same
            if (_selectedFood?.id == food.id) {
              _selectedFood = _selectedFood!.copyWith(isFavorite: false);
            }
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${food.name} dihapus dari favorit'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        final response = await _mealService.addToFavorites(food.id);
        if (response != null && response.success) {
          setState(() {
            // Update the food in the main list
            final index = _foods.indexWhere((f) => f.id == food.id);
            if (index != -1) {
              _foods[index] = _foods[index].copyWith(isFavorite: true);
            }

            // Add to favorites list
            final updatedFood = food.copyWith(isFavorite: true);
            _favoriteFoods.add(updatedFood);

            // Update selected food if it's the same
            if (_selectedFood?.id == food.id) {
              _selectedFood = _selectedFood!.copyWith(isFavorite: true);
            }
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${food.name} ditambahkan ke favorit'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah status favorit: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Food> get _filteredFoods {
    if (_selectedTab == 'Favorit') {
      return _favoriteFoods.where((food) {
        if (_searchController.text.isEmpty) return true;
        return food.name
            .toLowerCase()
            .contains(_searchController.text.toLowerCase());
      }).toList();
    }

    return _foods.where((food) {
      if (_searchController.text.isEmpty) return true;
      return food.name
          .toLowerCase()
          .contains(_searchController.text.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    final isMobileLandscape = isMobile && isLandscape;

    return AppLayout(
      title: 'Database Makanan Sehat',
      backgroundColor: const Color(0xFFF8F9FA),
      showBackButton: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (isMobileLandscape) {
            return _buildLandscapeLayout();
          } else {
            return _buildPortraitLayout();
          }
        },
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        // Header section
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFFF8F9FA),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildQuickStats(),
              const SizedBox(height: 16),
              ModernSearchField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {});
                  if (_selectedTab != 'Favorit') {
                    _loadFoods(refresh: true);
                  }
                },
                hintText: 'Cari makanan...',
              ),
              const SizedBox(height: 16),
              _isLoadingCategories
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: List.generate(
                          3,
                          (index) => Expanded(
                            child: Padding(
                              padding:
                                  EdgeInsets.only(right: index < 2 ? 8 : 0),
                              child: LoadingSkeleton(
                                height: 32,
                                borderRadius: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : CategoryFilterChips(
                      categories: _categories.map((cat) => cat.name).toList(),
                      selectedCategory: _selectedTab,
                      onCategorySelected: (category) {
                        setState(() {
                          _selectedTab = category;
                        });
                        if (_selectedTab != 'Favorit') {
                          _loadFoods(refresh: true);
                        }
                      },
                    ),
            ],
          ),
        ),

        // Content section
        Expanded(
          child: _selectedFood == null ? _buildFoodList() : _buildFoodDetails(),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side - Header, search, and filters
        SizedBox(
          width: 300, // Fixed width untuk left panel
          child: Container(
            color: const Color(0xFFF8F9FA),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCompactHeader(),
                  const SizedBox(height: 12),
                  ModernSearchField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {});
                      if (_selectedTab != 'Favorit') {
                        _loadFoods(refresh: true);
                      }
                    },
                    hintText: 'Cari makanan...',
                  ),
                  const SizedBox(height: 16),
                  _isLoadingCategories
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: List.generate(
                              4,
                              (index) => Padding(
                                padding:
                                    EdgeInsets.only(bottom: index < 3 ? 4 : 0),
                                child: LoadingSkeleton(
                                  height: 36,
                                  borderRadius: 8,
                                ),
                              ),
                            ),
                          ),
                        )
                      : _buildVerticalCategoryFilter(),
                ],
              ),
            ),
          ),
        ),

        // Divider
        Container(
          width: 1,
          color: Colors.grey.shade200,
        ),

        // Right side - Food list and details
        Expanded(
          child: _selectedFood == null
              ? _buildFoodList(isLandscape: true)
              : _buildFoodDetails(isLandscape: true),
        ),
      ],
    );
  }

  Widget _buildCompactHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Database Makanan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _selectedTab == 'Favorit'
              ? '${_favoriteFoods.length} favorit'
              : _selectedTab == 'Semua'
                  ? '${_foods.length}+ tersedia'
                  : '${_filteredFoods.length} makanan',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        // Compact stats
        Row(
          children: [
            _buildCompactStat(
              icon: Icons.restaurant_rounded,
              value: _foods.length.toString(),
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            _buildCompactStat(
              icon: Icons.category_rounded,
              value: _categories.length.toString(),
              color: AppColors.secondary,
            ),
            const SizedBox(width: 8),
            _buildCompactStat(
              icon: Icons.favorite_rounded,
              value: _favoriteFoods.length.toString(),
              color: Colors.red.shade400,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactStat({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalCategoryFilter() {
    final categories = [
      'Semua',
      'Favorit',
      ..._categories.map((cat) => cat.name)
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...categories.map(
          (category) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 4),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTab = category;
                });
                if (_selectedTab != 'Favorit') {
                  _loadFoods(refresh: true);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedTab == category
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedTab == category
                        ? AppColors.primary.withOpacity(0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: _selectedTab == category
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: _selectedTab == category
                        ? AppColors.primary
                        : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Database Makanan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _selectedTab == 'Favorit'
                  ? '${_favoriteFoods.length} makanan favorit'
                  : _selectedTab == 'Semua'
                      ? '${_foods.length}+ makanan tersedia'
                      : '${_filteredFoods.length} makanan dalam kategori',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.restaurant_menu_rounded,
            color: AppColors.primary,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.restaurant_rounded,
            label: 'Total Makanan',
            value: _foods.length.toString(),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: Icons.category_rounded,
            label: 'Kategori',
            value: _categories.length.toString(),
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: Icons.favorite_rounded,
            label: 'Favorit',
            value: _favoriteFoods.length.toString(),
            color: Colors.red.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList({bool isLandscape = false}) {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: TextStyle(fontSize: 16, color: Colors.red.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadFoods(refresh: true),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading && _foods.isEmpty) {
      return ListView.separated(
        shrinkWrap: isLandscape, // Add shrinkWrap for landscape
        physics: isLandscape
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) => const FoodItemSkeleton(),
      );
    }

    final filteredFoods = _filteredFoods;

    if (filteredFoods.isEmpty && !_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _selectedTab == 'Favorit'
                      ? Icons.favorite_border_rounded
                      : Icons.search_off_rounded,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _selectedTab == 'Favorit'
                    ? 'Belum ada makanan favorit'
                    : 'Tidak ada makanan yang ditemukan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedTab == 'Favorit'
                    ? 'Tap ikon hati untuk menambahkan favorit'
                    : 'Coba cari dengan kata kunci lain',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              if (_selectedTab != 'Favorit') ...[
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedTab = 'Semua';
                      _searchController.clear();
                    });
                    _loadFoods(refresh: true);
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset Filter'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
            _selectedTab != 'Favorit' &&
            _hasMoreData &&
            !_isLoading) {
          _loadFoods();
        }
        return false;
      },
      child: ListView.separated(
        shrinkWrap: isLandscape, // Add shrinkWrap for landscape
        physics: isLandscape
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: filteredFoods.length + (_isLoading ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == filteredFoods.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final food = filteredFoods[index];
          return FoodItem(
            food: food,
            onTap: () {
              setState(() {
                _selectedFood = food;
              });
            },
            onFavoriteToggle: () => _toggleFavorite(food),
          );
        },
      ),
    );
  }

  Widget _buildFoodDetails({bool isLandscape = false}) {
    final food = _selectedFood!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
                    Expanded(
                      child: Text(
                        food.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleFavorite(food),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: food.isFavorite
                                  ? Colors.red.shade50
                                  : Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              food.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 20,
                              color: food.isFavorite
                                  ? Colors.red.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${food.calories.toStringAsFixed(0)} kcal per ${food.weight?.toStringAsFixed(0) ?? "100"}g',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                if (food.category != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      food.category!.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Informasi Nutrisi (per 100g)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNutrientValue(
                        'Kalori', '${food.calories.toStringAsFixed(0)} kcal'),
                  ],
                ),
                const SizedBox(height: 12),
                NutrientBar(
                  label: 'Karbohidrat',
                  value: food.carbs,
                  unit: 'g',
                  color: AppColors.primary,
                  maxValue: 30,
                ),
                const SizedBox(height: 10),
                NutrientBar(
                  label: 'Protein',
                  value: food.protein,
                  unit: 'g',
                  color: AppColors.secondary,
                  maxValue: 10,
                ),
                const SizedBox(height: 10),
                NutrientBar(
                  label: 'Lemak',
                  value: food.fat,
                  unit: 'g',
                  color: Colors.orange,
                  maxValue: 10,
                ),
                if (food.vitamins != null && food.vitamins!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Vitamin',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...food.vitamins!.entries.map((entry) {
                    final vitaminName = entry.key;
                    final value = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: NutrientBar(
                        label: vitaminName,
                        value: value,
                        unit: 'mg',
                        color: AppColors.accent1,
                        maxValue: 150,
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 24),
                if (food.description != null && food.description!.isNotEmpty)
                  Text(
                    food.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Add to menu button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
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

          const SizedBox(height: 16),
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
