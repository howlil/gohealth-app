import 'dart:ui'; // Added to fix ImageFilter error
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/meal_type.dart';
import '../models/food_model.dart';
import '../models/meal_model.dart';
import '../services/meal_service.dart';
import '../widgets/navigations/app_layout.dart';
import '../utils/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/inputs/rounded_input_field.dart';
import '../widgets/inputs/nutrient_bar.dart';
import '../widgets/inputs/round_search_field.dart';
import '../widgets/inputs/tab_selector.dart';
import '../widgets/nutrition/food_search_result.dart';

class DailyNutritionTrackerScreen extends StatefulWidget {
  const DailyNutritionTrackerScreen({super.key});

  @override
  State<DailyNutritionTrackerScreen> createState() =>
      _DailyNutritionTrackerScreenState();
}

class _DailyNutritionTrackerScreenState
    extends State<DailyNutritionTrackerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _mealTimeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '100',
  );
  final TextEditingController _unitController = TextEditingController(
    text: 'gram',
  );

  final MealService _mealService = MealService();

  DateTime _selectedDate = DateTime.now();
  String _activeTab = 'Ringkasan Gizi';
  final List<String> _tabs = ['Ringkasan Gizi', 'Makanan Hari Ini'];
  String _selectedMealType = 'BREAKFAST';

  // Map to store meal type labels
  final Map<String, String> _mealTypeLabels = {
    'BREAKFAST': 'Sarapan',
    'LUNCH': 'Makan Siang',
    'DINNER': 'Makan Malam',
    'SNACK': 'Camilan',
  };

  List<Food> _searchResults = [];
  List<Meal> _meals = [];
  DailyMealSummary? _dailySummary;
  bool _isLoading = false;
  bool _isSearching = false;
  Timer? _debounce;

  final List<Food> _foodDatabase = [
    Food(
      id: '1',
      name: 'Apel',
      calories: 52,
      protein: 0.3,
      carbs: 13.8,
      fat: 0.2,
      weight: 100,
      nutrients: {
        'Karbohidrat': 13.8,
        'Protein': 0.3,
        'Lemak': 0.2,
        'Serat': 2.4,
      },
      vitamins: {},
      imageUrl: null,
      category: null,
      isFavorite: false,
      description:
          'Buah apel mengandung serat yang tinggi dan dapat membantu menjaga kesehatan pencernaan.',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Food(
      id: '2',
      name: 'Pisang',
      calories: 89,
      protein: 1.1,
      carbs: 22.8,
      fat: 0.3,
      weight: 100,
      nutrients: {
        'Karbohidrat': 22.8,
        'Protein': 1.1,
        'Lemak': 0.3,
        'Serat': 2.6,
      },
      vitamins: {},
      imageUrl: null,
      category: null,
      isFavorite: false,
      description:
          'Pisang kaya akan potasium dan vitamin B6 yang membantu fungsi jantung dan sistem saraf.',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Food(
      id: '3',
      name: 'Brokoli',
      calories: 55,
      protein: 2.8,
      carbs: 11.2,
      fat: 0.4,
      weight: 100,
      nutrients: {
        'Karbohidrat': 11.2,
        'Protein': 2.8,
        'Lemak': 0.4,
        'Serat': 2.6,
      },
      vitamins: {},
      imageUrl: null,
      category: null,
      isFavorite: true,
      description:
          'Brokoli adalah sayuran yang kaya vitamin C, vitamin K dan serat.',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Food(
      id: '4',
      name: 'Susu Rendah Lemak',
      calories: 42,
      protein: 3.5,
      carbs: 5.0,
      fat: 1.0,
      weight: 100,
      nutrients: {
        'Karbohidrat': 5.0,
        'Protein': 3.5,
        'Lemak': 1.0,
        'Serat': 0.0,
      },
      vitamins: {},
      imageUrl: null,
      category: null,
      isFavorite: false,
      description:
          'Susu rendah lemak menyediakan kalsium dan protein tanpa lemak jenuh yang tinggi.',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('d MMMM yyyy').format(_selectedDate);
    _mealTimeController.text = _mealTypeLabels[_selectedMealType] ?? 'Sarapan';

    // Tambahkan dummy data untuk testing
    _addDummyDataForTesting();

    _loadMeals();
    _loadDailySummary();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dateController.dispose();
    _mealTimeController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Load meals from API
  Future<void> _loadMeals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dateStr = _formatDateToDDMMYYYY(_selectedDate);
      debugPrint('Loading meals for date: $dateStr');

      final response = await _mealService.getMeals(date: dateStr);

      if (response != null && response.success && response.data != null) {
        final meals = response.data!['meals'] as List<Meal>;
        debugPrint('Loaded ${meals.length} meals');
        for (var meal in meals) {
          debugPrint(
              'Meal: ${meal.food?.name} - ${meal.mealType} - ${meal.totalCalories} kcal');
        }

        setState(() {
          // Hanya update jika ada data dari API
          if (meals.isNotEmpty) {
            _meals = meals;
          }
        });
      } else {
        debugPrint('No meals data from API, keeping existing data');
      }
    } catch (e) {
      debugPrint('Error loading meals: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load daily summary from API
  Future<void> _loadDailySummary() async {
    try {
      final dateStr = _formatDateToDDMMYYYY(_selectedDate);
      debugPrint('Loading daily summary for date: $dateStr');

      final response = await _mealService.getDailyMealSummary(date: dateStr);

      if (response != null && response.success && response.data != null) {
        debugPrint(
            'Daily summary loaded: ${response.data!.totalCalories} kcal');
        debugPrint(
            'Meals by type: ${response.data!.mealsByType.keys.toList()}');

        setState(() {
          // Hanya update jika ada data yang valid
          if (response.data!.totalCalories > 0 ||
              response.data!.mealsByType.values
                  .any((meals) => meals.isNotEmpty)) {
            _dailySummary = response.data;
          }
        });
      } else {
        debugPrint('No summary data from API, keeping existing data');
      }
    } catch (e) {
      debugPrint('Error loading daily summary: $e');
    }
  }

  String _formatDateToDDMMYYYY(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  // Date picker functionality
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('d MMMM yyyy').format(_selectedDate);
      });
      _loadMeals();
      _loadDailySummary();
    }
  }

  // Meal type dropdown functionality
  void _selectMealType() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Waktu Makan'),
          content: SizedBox(
            width: double.minPositive,
            child: ListView(
              shrinkWrap: true,
              children: _mealTypeLabels.entries.map((entry) {
                return ListTile(
                  title: Text(entry.value),
                  onTap: () {
                    setState(() {
                      _selectedMealType = entry.key;
                      _mealTimeController.text = entry.value;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // Search food with autocomplete
  void _searchFood(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty || query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final response = await _mealService.getFoodSuggestions(query: query);
        if (response != null && response.success && response.data != null) {
          setState(() {
            _searchResults = response.data!;
            _isSearching = false;
          });
        } else {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        }
      } catch (e) {
        debugPrint('Error searching food: $e');
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    });
  }

  void _selectFood(Food food) {
    setState(() {
      _searchController.text = food.name;
      _searchResults = [];
    });

    // Tampilkan bottom sheet untuk input jumlah
    _showAddFoodBottomSheet(food);
  }

  Future<void> _addFoodEntry(Food food, double quantity, String unit) async {
    try {
      final response = await _mealService.addMeal(
        foodId: food.id,
        mealType: _selectedMealType,
        quantity: quantity,
        unit: unit,
        date: _formatDateToDDMMYYYY(_selectedDate),
      );

      if (response != null && response.success) {
        setState(() {
          _searchController.clear();
        });
        _loadMeals();
        _loadDailySummary();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${food.name} ditambahkan ke ${_mealTimeController.text}',
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(10),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error adding meal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan makanan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMeal(String mealId) async {
    try {
      final response = await _mealService.deleteMeal(mealId);
      if (response != null && response.success) {
        _loadMeals();
        _loadDailySummary();
      }
    } catch (e) {
      debugPrint('Error deleting meal: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Pelacak Gizi Harian',
      backgroundColor: const Color(0xFFF8F9FA),
      showBackButton: false,
      currentIndex: 1,
      child: Stack(
        children: [
          // Background gradients
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(13),
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
                color: AppColors.secondary.withAlpha(13),
              ),
            ),
          ),

          // Main content
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildAddFoodSection(),
                    if (_searchResults.isNotEmpty || _isSearching)
                      _buildSearchResults(),
                    const SizedBox(height: 16),
                    TabSelector(
                      tabs: _tabs,
                      selectedIndex: _tabs.indexOf(_activeTab),
                      onTabSelected: (index) {
                        setState(() {
                          _activeTab = _tabs[index];
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Main content area - scrollable
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _activeTab == 'Ringkasan Gizi'
                                ? _buildNutritionSummary()
                                : _buildTodaysFoodList(),
                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddFoodSection() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tambah Makanan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: RoundedInputField(
                  controller: _dateController,
                  hintText: 'Pilih tanggal',
                  readOnly: true,
                  suffixIcon: Icons.calendar_today,
                  onSuffixIconTap: _selectDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RoundedInputField(
                  controller: _mealTimeController,
                  hintText: 'Pilih waktu makan',
                  readOnly: true,
                  suffixIcon: Icons.arrow_drop_down,
                  onSuffixIconTap: _selectMealType,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              RoundSearchField(
                controller: _searchController,
                onChanged: _searchFood,
                onSubmitted: (value) => _searchFood(value),
                hintText: 'Cari Makanan (min. 2 karakter)',
              ),
              if (_isSearching)
                Positioned(
                  right: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isSearching
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchResults.length,
              separatorBuilder: (context, index) =>
                  Divider(color: Colors.grey.shade200, height: 1),
              itemBuilder: (context, index) {
                final food = _searchResults[index];
                return FoodSearchResult(
                  food: food,
                  onTap: () => _selectFood(food),
                );
              },
            ),
    );
  }

  Widget _buildNutritionSummary() {
    final today = DateFormat('EEEE, d MMMM yyyy').format(_selectedDate);

    // Nilai target
    const targetCalories = 2000.0;
    const targetProtein = 50.0;
    const targetCarbs = 275.0;
    const targetFat = 65.0;

    // Nilai aktual dari daily summary
    final totalCalories = _dailySummary?.totalCalories ?? 0;
    final totalCarbs = _dailySummary?.totalCarbs ?? 0;
    final totalProtein = _dailySummary?.totalProtein ?? 0;
    final totalFat = _dailySummary?.totalFat ?? 0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Gizi Harian',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            today,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Calories and food count summary
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Kalori',
                  value: '${totalCalories.toInt()} kkal',
                  subtitle: 'dari $targetCalories kkal yang direkomendasikan',
                  progress: totalCalories / targetCalories,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Makanan',
                  value: '${_meals.length}',
                  subtitle: 'makanan dicatat hari ini',
                  showProgress: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Nutrient bars
          NutrientBar(
            label: 'Protein',
            value: totalProtein,
            maxValue: targetProtein,
            unit: 'g',
            color: AppColors.secondary,
          ),
          const SizedBox(height: 16),
          NutrientBar(
            label: 'Karbohidrat',
            value: totalCarbs,
            maxValue: targetCarbs,
            unit: 'g',
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          NutrientBar(
            label: 'Lemak',
            value: totalFat,
            maxValue: targetFat,
            unit: 'g',
            color: Colors.orange,
          ),
          const SizedBox(height: 24),

          // Distribusi Nutrisi heading
          const Text(
            'Distribusi Nutrisi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Pie chart
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildNutritionPieChart(
                    totalCarbs,
                    totalProtein,
                    totalFat,
                  ),
                ),
                Expanded(child: _buildChartLegend()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    double? progress,
    bool showProgress = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          if (showProgress && progress != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress > 1.0 ? 1.0 : progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 1.0 ? Colors.red : AppColors.primary,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutritionPieChart(double carbs, double protein, double fat) {
    // Calculate percentages
    final totalNutrients = carbs + protein + fat;
    if (totalNutrients == 0) {
      return const Center(
        child: Text('Belum ada data nutrisi'),
      );
    }

    final carbsPercentage = carbs / totalNutrients;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  value: carbs,
                  title: '',
                  color: AppColors.primary,
                  radius: 40,
                ),
                PieChartSectionData(
                  value: protein,
                  title: '',
                  color: AppColors.secondary,
                  radius: 40,
                ),
                PieChartSectionData(
                  value: fat,
                  title: '',
                  color: Colors.orange,
                  radius: 40,
                ),
              ],
            ),
          ),
        ),
        if (carbsPercentage > 0.6)
          Text(
            'Carb\n${(carbsPercentage * 100).toInt()}%',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  Widget _buildChartLegend() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegendItem('Protein', AppColors.secondary),
        const SizedBox(height: 8),
        _buildLegendItem('Karbohidrat', AppColors.primary),
        const SizedBox(height: 8),
        _buildLegendItem('Lemak', Colors.orange),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildTodaysFoodList() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Makanan Hari Ini',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Group meals by type
          ..._mealTypeLabels.entries.map((entry) {
            // Filter meals by mealType from _meals list
            final mealsForType =
                _meals.where((meal) => meal.mealType == entry.key).toList();

            return _buildMealSection(
              title: entry.value,
              meals: mealsForType,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMealSection({
    required String title,
    required List<Meal> meals,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (meals.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Belum ada makanan yang dicatat',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final meal = meals[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal.food?.name ?? 'Unknown Food',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${meal.totalCalories.toStringAsFixed(0)} kkal • ${meal.quantity} ${meal.unit}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade300,
                        size: 20,
                      ),
                      onPressed: () => _deleteMeal(meal.id),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showAddFoodBottomSheet(Food food) {
    _quantityController.text = '100';
    _unitController.text = 'gram';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tambah Makanan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        food.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${food.calories} kkal per ${food.weight ?? 100}g',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: RoundedInputField(
                              hintText: 'Jumlah',
                              keyboardType: TextInputType.number,
                              controller: _quantityController,
                              onChanged: (value) {
                                setModalState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RoundedInputField(
                              hintText: 'Satuan',
                              controller: _unitController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_quantityController.text.isNotEmpty)
                        Text(
                          'Total: ${((double.tryParse(_quantityController.text) ?? 0) / (food.weight ?? 100) * food.calories).toStringAsFixed(0)} kkal',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            final quantity =
                                double.tryParse(_quantityController.text) ??
                                    100;
                            final unit = _unitController.text.isNotEmpty
                                ? _unitController.text
                                : 'gram';
                            _addFoodEntry(food, quantity, unit);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'Tambahkan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Tambahkan method untuk dummy data
  void _addDummyDataForTesting() {
    // Dummy meals untuk testing
    _meals = [
      Meal(
        id: 'dummy1',
        userId: 'user1',
        foodId: 'BUAH-001',
        mealType: 'BREAKFAST',
        date: _formatDateToDDMMYYYY(_selectedDate),
        quantity: 150,
        unit: 'gram',
        totalCalories: 78,
        totalProtein: 0.9,
        totalFat: 0.3,
        totalCarbs: 19.5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        food: Food(
          id: 'BUAH-001',
          name: 'Apel',
          calories: 52,
          protein: 0.3,
          carbs: 13.8,
          fat: 0.2,
          weight: 100,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
      Meal(
        id: 'dummy2',
        userId: 'user1',
        foodId: 'DAGING-001',
        mealType: 'LUNCH',
        date: _formatDateToDDMMYYYY(_selectedDate),
        quantity: 100,
        unit: 'gram',
        totalCalories: 165,
        totalProtein: 31,
        totalFat: 3.6,
        totalCarbs: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        food: Food(
          id: 'DAGING-001',
          name: 'Dada Ayam',
          calories: 165,
          protein: 31,
          carbs: 0,
          fat: 3.6,
          weight: 100,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
    ];

    // Dummy daily summary
    _dailySummary = DailyMealSummary(
      date: _formatDateToDDMMYYYY(_selectedDate),
      totalCalories: 243,
      totalProtein: 31.9,
      totalFat: 3.9,
      totalCarbs: 19.5,
      mealsByType: {
        'BREAKFAST': [_meals[0]],
        'LUNCH': [_meals[1]],
        'DINNER': [],
        'SNACK': [],
      },
    );
  }
}
