import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../widgets/navigations/app_layout.dart';
import '../utils/app_colors.dart';
import '../utils/responsive_helper.dart';
import '../widgets/glass_card.dart';
import '../widgets/home/stat_chip.dart';
import '../widgets/home/action_glass_card.dart';
import '../providers/dashboard_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/notification_provider.dart';
import 'package:go_router/go_router.dart';
import '../widgets/navigations/responsive_layout.dart';

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
      context.read<NotificationProvider>().loadUnreadCount();
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

              return AdaptiveLayout(
                builder: (context, constraints) {
                  final isLandscape = ResponsiveHelper.isLandscape(context);
                  final isTabletOrDesktop =
                      ResponsiveHelper.isTablet(context) ||
                          ResponsiveHelper.isDesktop(context);

                  return SingleChildScrollView(
                    padding: ResponsiveHelper.getAdaptivePadding(context),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: ResponsiveHelper.getResponsiveValue(
                            context,
                            mobile: double.infinity,
                            tablet: 800,
                            desktop: 1200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                                height: ResponsiveHelper.getAdaptiveSpacing(
                                    context,
                                    baseSpacing: 16)),
                            _buildHeader(dashboardProvider),
                            SizedBox(
                                height: ResponsiveHelper.getAdaptiveSpacing(
                                    context,
                                    baseSpacing: 16)),
                            _buildStatCards(dashboardProvider),
                            SizedBox(
                                height: ResponsiveHelper.getAdaptiveSpacing(
                                    context,
                                    baseSpacing: 24)),

                            // Responsive layout untuk konten utama
                            if (isTabletOrDesktop ||
                                (ResponsiveHelper.isMobile(context) &&
                                    isLandscape))
                              _buildDesktopLayout(dashboardProvider)
                            else
                              _buildMobileLayout(dashboardProvider),

                            SizedBox(
                                height: ResponsiveHelper.getAdaptiveSpacing(
                                    context,
                                    baseSpacing: 24)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(DashboardProvider dashboardProvider) {
    final userName = dashboardProvider.userName;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hey ${userName.split(' ').first}",
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                'Selamat datang di GoHealth',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            return SizedBox(
              width: 48, // Fixed width untuk mencegah overflow
              height: 48, // Fixed height
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      context.push('/notifications');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.notifications_outlined,
                            size: 24,
                            color: Colors.grey.shade700,
                          ),
                          if (notificationProvider.unreadCount > 0)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  maxWidth: 24,
                                ),
                                height: 16,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.white, width: 1),
                                ),
                                child: Center(
                                  child: Text(
                                    notificationProvider.unreadCount > 99
                                        ? '99+'
                                        : notificationProvider.unreadCount
                                            .toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      height: 1,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
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
    final labels = dashboardProvider.chartLabels;
    final timeRange = dashboardProvider.timeRange;

    // Calculate statistics
    double averageCalories = 0;
    double minY = 0;
    double maxY = 3000; // Default max

    if (spots.isNotEmpty) {
      final calorieValues = spots.map((spot) => spot.y).toList();
      averageCalories =
          calorieValues.reduce((a, b) => a + b) / calorieValues.length;

      // Calculate reasonable Y-axis bounds
      final maxValue = calorieValues.reduce((a, b) => a > b ? a : b);
      final minValue = calorieValues.reduce((a, b) => a < b ? a : b);

      // Add padding to the max value
      maxY = (maxValue * 1.2).ceilToDouble();
      if (maxY < 1000) maxY = 1000;

      // Set minimum with some padding
      minY = (minValue * 0.8).floorToDouble();
      if (minY < 0) minY = 0;
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Calories Tracker',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (spots.isNotEmpty)
                    Text(
                      'Average: ${averageCalories.toStringAsFixed(0)} kcal',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
              _buildTimeRangeSelector(dashboardProvider),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: spots.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.insert_chart_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No data available',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: (maxY - minY) / 5,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade200,
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade100,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= labels.length ||
                                  value.toInt() < 0 ||
                                  value != value.toInt()) {
                                return const SizedBox.shrink();
                              }

                              // Show every nth label based on data length
                              final showInterval = labels.length > 7 ? 2 : 1;
                              if (value.toInt() % showInterval != 0) {
                                return const SizedBox.shrink();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  labels[value.toInt()],
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (maxY - minY) / 5,
                            reservedSize: 45,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  '${value.toInt()}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      minX: 0,
                      maxX: spots.length - 1.0,
                      minY: minY,
                      maxY: maxY,
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) =>
                              Colors.black87.withOpacity(0.8),
                          tooltipPadding: const EdgeInsets.all(8),
                          tooltipMargin: 8,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((touchedSpot) {
                              final spot = touchedSpot;
                              if (spot.x.toInt() >= labels.length) {
                                return null;
                              }

                              return LineTooltipItem(
                                '${labels[spot.x.toInt()]}\n${spot.y.toStringAsFixed(0)} kcal',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                        touchCallback: (FlTouchEvent event,
                            LineTouchResponse? response) {},
                        handleBuiltInTouches: true,
                      ),
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          if (averageCalories > 0)
                            HorizontalLine(
                              y: averageCalories,
                              color: Colors.orange.withOpacity(0.7),
                              strokeWidth: 2,
                              dashArray: [8, 4],
                              label: HorizontalLineLabel(
                                show: true,
                                alignment: Alignment.topRight,
                                padding:
                                    const EdgeInsets.only(right: 5, bottom: 5),
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                labelResolver: (line) => 'Avg',
                              ),
                            ),
                          if (dashboardProvider.caloriesTarget > 0)
                            HorizontalLine(
                              y: dashboardProvider.caloriesTarget,
                              color: Colors.red.withOpacity(0.5),
                              strokeWidth: 2,
                              dashArray: [8, 4],
                              label: HorizontalLineLabel(
                                show: true,
                                alignment: Alignment.topRight,
                                padding:
                                    const EdgeInsets.only(right: 5, top: 5),
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                labelResolver: (line) => 'Target',
                              ),
                            ),
                        ],
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: AppColors.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              // Highlight dots that are above target
                              final isAboveTarget =
                                  dashboardProvider.caloriesTarget > 0 &&
                                      spot.y > dashboardProvider.caloriesTarget;

                              return FlDotCirclePainter(
                                radius: 5,
                                color: isAboveTarget
                                    ? Colors.red
                                    : AppColors.primary,
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
          if (spots.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem(
                    color: AppColors.primary,
                    label: 'Consumed',
                  ),
                  _buildLegendItem(
                    color: Colors.orange,
                    label: 'Average',
                    isDashed: true,
                  ),
                  _buildLegendItem(
                    color: Colors.red,
                    label: 'Target',
                    isDashed: true,
                  ),
                ],
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

  Widget _buildLegendItem({
    required Color color,
    required String label,
    bool isDashed = false,
  }) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
          color: isDashed ? Colors.transparent : color,
          child: isDashed
              ? Row(
                  children: List.generate(
                      3,
                      (index) => Expanded(
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal: index.isOdd ? 1 : 0),
                              height: 2,
                              color: index.isEven ? color : Colors.transparent,
                            ),
                          )),
                )
              : null,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(DashboardProvider dashboardProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildCaloriesTracker(dashboardProvider),
        ),
        SizedBox(
            width:
                ResponsiveHelper.getAdaptiveSpacing(context, baseSpacing: 24)),
        Expanded(
          child: Column(
            children: [
              _buildActionCards(),
              SizedBox(
                  height: ResponsiveHelper.getAdaptiveSpacing(context,
                      baseSpacing: 24)),
              _buildBottomStats(dashboardProvider),
              SizedBox(
                  height: ResponsiveHelper.getAdaptiveSpacing(context,
                      baseSpacing: 24)),
              _buildNutritionSummary(dashboardProvider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(DashboardProvider dashboardProvider) {
    return Column(
      children: [
        _buildCaloriesTracker(dashboardProvider),
        SizedBox(
            height:
                ResponsiveHelper.getAdaptiveSpacing(context, baseSpacing: 24)),
        _buildActionCards(),
        SizedBox(
            height:
                ResponsiveHelper.getAdaptiveSpacing(context, baseSpacing: 24)),
        _buildNutritionSummary(dashboardProvider),
        SizedBox(
            height:
                ResponsiveHelper.getAdaptiveSpacing(context, baseSpacing: 24)),
        _buildBottomStats(dashboardProvider),
      ],
    );
  }
}
