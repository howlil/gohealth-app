import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../widgets/navigations/app_layout.dart';
import '../utils/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/home/stat_chip.dart';
import '../widgets/home/action_glass_card.dart';
import '../providers/dashboard_provider.dart';
import '../providers/profile_provider.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboardData();
      context.read<ProfileProvider>().initializeProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'GoHealth',
      backgroundColor: const Color(0xFFF8F9FA),
      showBackButton: false,
      currentIndex: 0,
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
                color: AppColors.primary.withOpacity(0.1),
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
                color: AppColors.secondary.withOpacity(0.08),
              ),
            ),
          ),

          // Main content
          Consumer<DashboardProvider>(
            builder: (context, dashboardProvider, child) {
              if (dashboardProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (dashboardProvider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: ${dashboardProvider.error}',
                        style: TextStyle(color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => dashboardProvider.loadDashboardData(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildHeader(dashboardProvider),
                    const SizedBox(height: 16),
                    _buildStatCards(dashboardProvider),
                    const SizedBox(height: 24),
                    _buildCaloriesTracker(dashboardProvider),
                    const SizedBox(height: 24),
                    _buildActionCards(),
                    const SizedBox(height: 24),
                    _buildNutritionSummary(dashboardProvider),
                    const SizedBox(height: 24),
                    _buildBottomStats(dashboardProvider),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(DashboardProvider dashboardProvider) {
    final userName = dashboardProvider.userName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hey ${userName.split(' ').first}",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          'Selamat datang di GoHealth',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildStatCards(DashboardProvider dashboardProvider) {
    final startWeight = dashboardProvider.weightGoalStartWeight;
    final targetWeight = dashboardProvider.weightGoalTargetWeight;
    final dailyCal = dashboardProvider.caloriesTarget.toInt();

    return Row(
      children: [
        Expanded(
          child: StatChip(
            title: 'Start Weight',
            value: '${startWeight.toStringAsFixed(1)} KG',
            color: AppColors.primary.withOpacity(0.8),
            iconData: Icons.monitor_weight_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatChip(
            title: 'Goal',
            value: '${targetWeight.toStringAsFixed(1)} KG',
            color: AppColors.secondary.withOpacity(0.8),
            iconData: Icons.flag_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatChip(
            title: 'Daily Cal',
            value: '$dailyCal',
            color: AppColors.accent1.withOpacity(0.8),
            iconData: Icons.local_fire_department_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildCaloriesTracker(DashboardProvider dashboardProvider) {
    final spots = dashboardProvider.caloriesSpots;
    final maxY = spots.isEmpty
        ? 2000.0
        : (spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) + 500.0)
            .roundToDouble();
    final labels = dashboardProvider.chartLabels;
    final timeRange = dashboardProvider.timeRange;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Calories Tracker',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildTimeRangeSelector(dashboardProvider),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: spots.isEmpty
                ? Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 4,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade200,
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= labels.length ||
                                  value.toInt() < 0) {
                                return const SizedBox.shrink();
                              }
                              final style = TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              );
                              String text = labels[value.toInt()];
                              return Text(text, style: style);
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: maxY / 4,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: spots.length - 1.0,
                      minY: 0,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: AppColors.primary,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.3),
                                AppColors.primary.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector(DashboardProvider dashboardProvider) {
    final currentRange = dashboardProvider.timeRange;

    return GlassCard(
      padding: EdgeInsets.zero,
      color: AppColors.primary.withOpacity(0.05),
      borderColor: AppColors.primary.withOpacity(0.1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimeRangeButton(
            text: 'Week',
            isSelected: currentRange == 'week',
            onTap: () => dashboardProvider.changeTimeRange('week'),
          ),
          _buildTimeRangeButton(
            text: 'Month',
            isSelected: currentRange == 'month',
            onTap: () => dashboardProvider.changeTimeRange('month'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildActionCards() {
    return Row(
      children: [
        Expanded(
          child: ActionGlassCard(
            title: 'BMI',
            subtitle: 'Control Your Weight',
            icon: Icons.monitor_weight_outlined,
            color: AppColors.secondary,
            onTap: () => context.go('/bmi'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ActionGlassCard(
            title: 'Food',
            subtitle: 'Healthy Food List',
            icon: Icons.restaurant_outlined,
            color: AppColors.primary,
            onTap: () => context.go('/food'),
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionSummary(DashboardProvider dashboardProvider) {
    final nutritionSummary = dashboardProvider.nutritionSummary;

    if (nutritionSummary == null) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Nutrition Recommendation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Calories
          _buildNutrientRow(
            icon: Icons.local_fire_department_outlined,
            title: 'Calories',
            min: nutritionSummary.calories.min,
            max: nutritionSummary.calories.max,
            unit: 'kcal',
            color: AppColors.accent1,
          ),
          const SizedBox(height: 12),

          // Protein
          _buildNutrientRow(
            icon: Icons.fitness_center_outlined,
            title: 'Protein',
            min: nutritionSummary.protein.min,
            max: nutritionSummary.protein.max,
            unit: nutritionSummary.protein.unit,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),

          // Carbs
          _buildNutrientRow(
            icon: Icons.grain_outlined,
            title: 'Carbohydrate',
            min: nutritionSummary.carbohydrate.min,
            max: nutritionSummary.carbohydrate.max,
            unit: nutritionSummary.carbohydrate.unit,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 12),

          // Fat
          _buildNutrientRow(
            icon: Icons.opacity_outlined,
            title: 'Fat',
            min: nutritionSummary.fat.min,
            max: nutritionSummary.fat.max,
            unit: nutritionSummary.fat.unit,
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientRow({
    required IconData icon,
    required String title,
    required int min,
    required int max,
    required String unit,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '$min - $max $unit',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Essential',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomStats(DashboardProvider dashboardProvider) {
    final bmi = dashboardProvider.bmiValue;
    final status = dashboardProvider.bmiStatus;
    final caloriesNeed = dashboardProvider.caloriesTarget.toInt();

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(
            title: 'BMI',
            value: bmi.toStringAsFixed(1),
            icon: Icons.monitor_weight_outlined,
            color: AppColors.primary,
          ),
          _buildDivider(),
          _buildStatItem(
            title: 'Status',
            value: _formatBmiStatus(status),
            icon: Icons.check_circle_outline,
            color: _getBmiStatusColor(status),
          ),
          _buildDivider(),
          _buildStatItem(
            title: 'Cal. Need',
            value: caloriesNeed.toString(),
            icon: Icons.local_fire_department_outlined,
            color: AppColors.accent1,
          ),
        ],
      ),
    );
  }

  String _formatBmiStatus(String status) {
    if (status.isEmpty) return 'Unknown';

    // Convert from SNAKE_CASE to Title Case
    final words = status.split('_');
    if (words.isEmpty) return 'Unknown';

    if (words.length == 1) {
      return words[0][0].toUpperCase() + words[0].substring(1).toLowerCase();
    }

    return words
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Color _getBmiStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'UNDERWEIGHT':
        return Colors.blue;
      case 'NORMAL':
        return Colors.green;
      case 'OVERWEIGHT':
        return Colors.orange;
      case 'OBESE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 40, width: 1, color: Colors.grey.shade300);
  }
}
