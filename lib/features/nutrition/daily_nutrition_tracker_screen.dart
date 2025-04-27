import 'dart:ui'; // Added to fix ImageFilter error
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/layouts/app_layout.dart';
import '../../core/utils/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/rounded_input_field.dart';
import '../../core/widgets/nutrient_bar.dart';
import '../foods/models/food_model.dart';
import '../../core/widgets/round_search_field.dart';
import '../../core/widgets/tab_selector.dart';
import 'models/meal_type.dart';
import 'widgets/food_search_result.dart';

class FoodLogEntry {
  final Food food;
  final MealType mealType;
  final DateTime timestamp;
  final double quantity; 

  FoodLogEntry({
    required this.food,
    required this.mealType,
    required this.timestamp,
    required this.quantity,
  });

  double get calories => food.calories * (quantity / 100);

  Map<String, double> get nutrients {
    final result = <String, double>{};
    food.nutrients.forEach((key, value) {
      result[key] = value * (quantity / 100);
    });
    return result;
  }
}

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

  DateTime _selectedDate = DateTime.now();
  String _activeTab = 'Ringkasan Gizi';
  final List<String> _tabs = ['Ringkasan Gizi', 'Makanan Hari Ini'];
  MealType _selectedMealType = MealType.breakfast;

  List<Food> _searchResults = [];
  Food? _selectedFood;

  final List<Food> _foodDatabase = [
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
      vitamins: {},
      imageUrl: null,
      category: 'Buah-buahan',
      isFavorite: false,
      description:
          'Buah apel mengandung serat yang tinggi dan dapat membantu menjaga kesehatan pencernaan.',
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
      vitamins: {},
      imageUrl: null,
      category: 'Sayuran',
      isFavorite: true,
      description:
          'Brokoli adalah sayuran yang kaya vitamin C, vitamin K dan serat.',
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

  final List<FoodLogEntry> _foodEntries = [];

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('d MMMM yyyy').format(_selectedDate);
    _mealTimeController.text = 'Sarapan';

    // Menambahkan contoh makanan yang sudah dimasukkan
    _foodEntries.add(
      FoodLogEntry(
        food: _foodDatabase.firstWhere((food) => food.name == 'Pisang'),
        mealType: MealType.breakfast,
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        quantity: 100,
      ),
    );

    _foodEntries.add(
      FoodLogEntry(
        food: _foodDatabase.firstWhere((food) => food.name == 'Pisang'),
        mealType: MealType.lunch,
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        quantity: 100,
      ),
    );

    _foodEntries.add(
      FoodLogEntry(
        food: _foodDatabase.firstWhere(
          (food) => food.name == 'Susu Rendah Lemak',
        ),
        mealType: MealType.dinner,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        quantity: 100,
      ),
    );
  }

  // Pengelompokan makanan berdasarkan jenis makanan
  Map<MealType, List<FoodLogEntry>> get _groupedFoodEntries {
    final map = <MealType, List<FoodLogEntry>>{};
    for (var mealType in MealType.values) {
      map[mealType] =
          _foodEntries.where((entry) => entry.mealType == mealType).toList();
    }
    return map;
  }

  // Menghitung total nutrisi dari semua makanan
  Map<String, double> get _totalNutrients {
    final result = <String, double>{
      'Karbohidrat': 0,
      'Protein': 0,
      'Lemak': 0,
      'Serat': 0,
    };

    for (var entry in _foodEntries) {
      entry.nutrients.forEach((key, value) {
        result[key] = (result[key] ?? 0) + value;
      });
    }

    return result;
  }

  // Total kalori
  double get _totalCalories {
    return _foodEntries.fold(0, (sum, entry) => sum + entry.calories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dateController.dispose();
    _mealTimeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _searchFood(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    // Filter database berdasarkan query
    final results =
        _foodDatabase.where((food) {
          return food.name.toLowerCase().contains(query.toLowerCase());
        }).toList();

    setState(() {
      _searchResults = results;
    });
  }

  void _selectFood(Food food) {
    setState(() {
      _selectedFood = food;
      _searchController.text = food.name;
      _searchResults = [];
    });

    // Tampilkan bottom sheet untuk input jumlah
    _showAddFoodBottomSheet(food);
  }

  void _addFoodEntry(Food food, double quantity) {
    // Tambahkan makanan ke dalam log
    final entry = FoodLogEntry(
      food: food,
      mealType: _selectedMealType,
      timestamp: DateTime.now(),
      quantity: quantity,
    );

    setState(() {
      _foodEntries.add(entry);
      _searchController.clear();
      _selectedFood = null;
    });
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
                    if (_searchResults.isNotEmpty) _buildSearchResults(),
                    const SizedBox(height: 16),
                    TabSelector(
                      tabs: _tabs,
                      selectedTab: _activeTab,
                      onTabSelected: (tab) {
                        setState(() {
                          _activeTab = tab;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Main content area - scrollable
              Expanded(
                child: SingleChildScrollView(
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
                  // Removed invalid 'readOnly' and 'onTap' parameters
                  // Removed 'labelText' parameter
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RoundedInputField(
                  controller: _mealTimeController,
                  hintText: 'Pilih waktu makan',
                  // Removed invalid 'readOnly' and 'onTap' parameters
                  // Removed 'labelText' parameter
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RoundSearchField(
            controller: _searchController,
            onChanged: _searchFood,
            onSubmitted: (value) => _searchFood(value),
            hintText: 'Cari Makanan',
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
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _searchResults.length,
        separatorBuilder:
            (context, index) => Divider(color: Colors.grey.shade200, height: 1),
        itemBuilder: (context, index) {
          final food = _searchResults[index];
          return FoodSearchResult(food: food, onTap: () => _selectFood(food));
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
    const targetFiber = 25.0;

    // Nilai aktual
    final totalCalories = _totalCalories;
    final totalCarbs = _totalNutrients['Karbohidrat'] ?? 0;
    final totalProtein = _totalNutrients['Protein'] ?? 0;
    final totalFat = _totalNutrients['Lemak'] ?? 0;
    final totalFiber = _totalNutrients['Serat'] ?? 0;

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
                  value: '${_foodEntries.length}',
                  subtitle: 'makanan dicatat hari ini',
                  showProgress: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Nutrient bars
          NutrientBar( // Changed from NutrientBar to NutrientBar
            label: 'Protein',
            value: totalProtein,
            maxValue: targetProtein,
            unit: 'g',
            color: AppColors.secondary,
          ),
          const SizedBox(height: 16),
          NutrientBar( // Changed from NutrientBar to NutrientBar
            label: 'Karbohidrat',
            value: totalCarbs,
            maxValue: targetCarbs,
            unit: 'g',
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          NutrientBar( // Changed from NutrientBar to NutrientBar
            label: 'Lemak',
            value: totalFat,
            maxValue: targetFat,
            unit: 'g',
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          NutrientBar( // Changed from NutrientBar to NutrientBar
            label: 'Serat',
            value: totalFiber,
            maxValue: targetFiber,
            unit: 'g',
            color: Colors.purple,
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
    final carbsPercentage = totalNutrients > 0 ? carbs / totalNutrients : 0;
    // Remove unused variables
    //final proteinPercentage = totalNutrients > 0 ? protein / totalNutrients : 0;
    //final fatPercentage = totalNutrients > 0 ? fat / totalNutrients : 0;

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
        carbsPercentage > 0.6
            ? Text(
              'Carb\n${(carbsPercentage * 100).toInt()}%',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            )
            : const SizedBox(),
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

          // Breakfast
          _buildMealSection(
            title: 'Sarapan',
            entries: _groupedFoodEntries[MealType.breakfast] ?? [],
          ),

          // Lunch
          _buildMealSection(
            title: 'Makan Siang',
            entries: _groupedFoodEntries[MealType.lunch] ?? [],
          ),

          // Dinner
          _buildMealSection(
            title: 'Makan Malam',
            entries: _groupedFoodEntries[MealType.dinner] ?? [],
          ),

          // Snacks
          _buildMealSection(
            title: 'Camilan',
            entries: _groupedFoodEntries[MealType.snack] ?? [],
            showEmptyMessage: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection({
    required String title,
    required List<FoodLogEntry> entries,
    bool showEmptyMessage = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty && showEmptyMessage)
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
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.food.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${entry.calories.toInt()} kkal',
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
                      onPressed: () {
                        // Remove food entry
                        setState(() {
                          _foodEntries.remove(entry);
                        });
                      },
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
                        '${food.calories} kkal per ${food.weight}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      RoundedInputField(
                        // Removed invalid 'labelText' parameter
                        hintText: 'Masukkan jumlah gram',
                        keyboardType: TextInputType.number,
                        controller: _quantityController,
                        onChanged: (value) {
                          setModalState(() {});
                        },
                      ),
                      const SizedBox(height: 8),
                      if (_quantityController.text.isNotEmpty)
                        Text(
                          'Total: ${(double.tryParse(_quantityController.text) ?? 0) / 100 * food.calories} kkal',
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
                            _addFoodEntry(food, quantity);
                            Navigator.pop(context);
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

  Widget _buildMealTimeDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Pilih Waktu Makan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMealTimeOption('Sarapan', MealType.breakfast),
          _buildMealTimeOption('Makan Siang', MealType.lunch),
          _buildMealTimeOption('Makan Malam', MealType.dinner),
          _buildMealTimeOption('Camilan', MealType.snack),
        ],
      ),
    );
  }

  Widget _buildMealTimeOption(String mealTime, MealType type) {
    return ListTile(
      title: Text(mealTime),
      onTap: () {
        setState(() {
          _mealTimeController.text = mealTime;
          _selectedMealType = type;
        });
        Navigator.pop(context);
      },
      );
 }
}