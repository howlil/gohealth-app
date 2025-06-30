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
import '../services/fcm_service.dart';
import '../widgets/loading_skeleton.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static bool _fcmTokenSent =
      false; // Track if FCM token was sent in this session

  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboardData();
      context.read<ProfileProvider>().initializeProfile();
      try {
        context.read<NotificationProvider>().loadUnreadCount();
      } catch (e) {
        debugPrint('Error loading notification count: $e');
        // Tangani error dengan diam-diam
      }

      // Send FCM token to server when user reaches homepage
      _sendFCMTokenToServer();
    });
  }

  Future<void> _sendFCMTokenToServer() async {
    // Only send FCM token once per session
    if (_fcmTokenSent) {
      debugPrint(
          '🏠 HomeScreen: FCM token already sent in this session, skipping');
      return;
    }

    try {
      debugPrint('🏠 HomeScreen: Sending FCM token to server...');
      await FCMService().sendTokenToServer();
      _fcmTokenSent = true; // Mark as sent
      debugPrint('✅ HomeScreen: FCM token sent to server successfully');
    } catch (e) {
      debugPrint('⚠️ HomeScreen: Failed to send FCM token: $e');
      // Don't show error to user for FCM token failure
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when user returns to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboardProvider = context.read<DashboardProvider>();
      debugPrint('🔄 Home screen focus - refreshing dashboard data');
      dashboardProvider.loadDashboardData();
    });
  }

  // Date picker functionality

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

          // Main content with RefreshIndicator
          RefreshIndicator(
            onRefresh: () async {
              debugPrint('🔄 Pull to refresh - reloading dashboard data');
              final dashboardProvider = context.read<DashboardProvider>();
              await dashboardProvider.loadDashboardData();
              await context.read<ProfileProvider>().initializeProfile();
              try {
                await context.read<NotificationProvider>().loadUnreadCount();
              } catch (e) {
                debugPrint('Error refreshing notification count: $e');
                // Tangani error dengan diam-diam
              }
            },
            child: Consumer<DashboardProvider>(
              builder: (context, dashboardProvider, child) {
                if (dashboardProvider.isLoading) {
                  return const DashboardSkeleton();
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
                          onPressed: () =>
                              dashboardProvider.loadDashboardData(),
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

                    return LayoutBuilder(
                      builder: (context, boxConstraints) {
                        final isMobile = ResponsiveHelper.isMobile(context);
                        final isMobileLandscape = isMobile && isLandscape;

                        if (isMobileLandscape) {
                          return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              children: [
                                // Header area - sekarang ikut scroll
                                Container(
                                  color: const Color(0xFFF8F9FA),
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                  child: Column(
                                    children: [
                                      _buildHeader(dashboardProvider),
                                      const SizedBox(height: 8),
                                      _buildStatCards(dashboardProvider),
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                                ),

                                // Content area - mobile layout vertikal
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                  child: _buildMobileLayout(dashboardProvider),
                                ),
                              ],
                            ),
                          );
                        }

                        // Fully scrollable layout untuk portrait
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              // Header area - sekarang ikut scroll
                              Container(
                                color: const Color(0xFFF8F9FA),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                child: Column(
                                  children: [
                                    _buildHeader(dashboardProvider),
                                    const SizedBox(height: 8),
                                    _buildStatCards(dashboardProvider),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),

                              // Content area - ikut dalam scroll yang sama
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        ResponsiveHelper.getResponsiveValue(
                                      context,
                                      mobile: double.infinity,
                                      tablet: 800,
                                      desktop: 1200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (isTabletOrDesktop && !isMobile)
                                        _buildDesktopLayout(dashboardProvider)
                                      else
                                        _buildMobileLayout(dashboardProvider),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(DashboardProvider dashboardProvider) {
    final userName = dashboardProvider.userName;
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    final isMobileLandscape = isMobile && isLandscape;

    return Container(
      height: isMobileLandscape ? 36 : 48, // Lebih kecil untuk mobile landscape
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Hey ${userName.split(' ').first}",
                    style: TextStyle(
                      fontSize: isMobileLandscape ? 16 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (!isMobileLandscape) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Selamat datang di GoHealth',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Container(
                width: isMobileLandscape ? 36 : 40,
                height: isMobileLandscape ? 36 : 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(isMobileLandscape ? 8 : 10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(isMobileLandscape ? 8 : 10),
                    onTap: () {
                      try {
                        context.push('/notifications');
                      } catch (e) {
                        debugPrint('Error navigating to notifications: $e');
                      }
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          size: isMobileLandscape ? 16 : 18,
                          color: Colors.grey.shade700,
                        ),
                        if (notificationProvider.unreadCount > 0)
                          Positioned(
                            right: isMobileLandscape ? 4 : 6,
                            top: isMobileLandscape ? 4 : 6,
                            child: Container(
                              constraints: BoxConstraints(
                                minWidth: isMobileLandscape ? 10 : 12,
                                maxWidth: isMobileLandscape ? 16 : 18,
                                minHeight: isMobileLandscape ? 10 : 12,
                                maxHeight: isMobileLandscape ? 10 : 12,
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(
                                    isMobileLandscape ? 5 : 6),
                                border:
                                    Border.all(color: Colors.white, width: 1),
                              ),
                              child: Center(
                                child: Text(
                                  notificationProvider.unreadCount > 9
                                      ? '9+'
                                      : notificationProvider.unreadCount
                                          .toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isMobileLandscape ? 6 : 7,
                                    fontWeight: FontWeight.bold,
                                    height: 1,
                                  ),
                                  textAlign: TextAlign.center,
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(DashboardProvider dashboardProvider) {
    final startWeight = dashboardProvider.weightGoalStartWeight;
    final targetWeight = dashboardProvider.weightGoalTargetWeight;
    final dailyCal = dashboardProvider.caloriesTarget.toInt();

    final isLandscape = ResponsiveHelper.isLandscape(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    final isMobileLandscape = isMobile && isLandscape;

    return Container(
      height: isMobileLandscape
          ? 45
          : (isLandscape ? 55 : 60), // Lebih kecil untuk mobile landscape
      child: Row(
        children: [
          Expanded(
            child: StatChip(
              title: 'Start Weight',
              value: startWeight > 0
                  ? '${startWeight.toStringAsFixed(1)} KG'
                  : '- KG',
              color: AppColors.primary.withOpacity(0.8),
              iconData: Icons.monitor_weight_outlined,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatChip(
              title: 'Goal',
              value: targetWeight > 0
                  ? '${targetWeight.toStringAsFixed(1)} KG'
                  : '- KG',
              color: AppColors.secondary.withOpacity(0.8),
              iconData: Icons.flag_outlined,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatChip(
              title: 'Daily Cal',
              value: dailyCal > 0 ? '$dailyCal' : '-',
              color: AppColors.accent1.withOpacity(0.8),
              iconData: Icons.local_fire_department_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesTracker(DashboardProvider dashboardProvider) {
    final spots = dashboardProvider.caloriesSpots;
    final labels = dashboardProvider.chartLabels;
    final timeRange = dashboardProvider.timeRange;
    final caloriesTarget = dashboardProvider.caloriesTarget;
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    final isMobileLandscape = isMobile && isLandscape;

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

      // Add padding to the max value, consider target in calculation
      maxY = [maxValue * 1.2, caloriesTarget * 1.1, 1000.0]
          .reduce((a, b) => a > b ? a : b)
          .ceilToDouble();

      // Set minimum with some padding
      minY = (minValue * 0.8).floorToDouble();
      if (minY < 0) minY = 0;
    } else if (caloriesTarget > 0) {
      // If no data but have target, set max based on target
      maxY = (caloriesTarget * 1.2).ceilToDouble();
    }

    return GlassCard(
      padding: EdgeInsets.all(isMobileLandscape ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header responsif
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Calories Tracker',
                      style: TextStyle(
                        fontSize: isMobileLandscape ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isMobileLandscape)
                      Row(
                        children: [
                          Text(
                            spots.isNotEmpty
                                ? 'Average: ${averageCalories.toStringAsFixed(0)} kcal'
                                : caloriesTarget > 0
                                    ? 'Target: ${caloriesTarget.toStringAsFixed(0)} kcal'
                                    : 'No target set',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Today button
                          GestureDetector(
                            onTap: () async {
                              await dashboardProvider.setToday();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: AppColors.primary.withOpacity(0.3)),
                              ),
                              child: Text(
                                'Today',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              _buildTimeRangeSelector(dashboardProvider),
            ],
          ),
          SizedBox(height: isMobileLandscape ? 8 : 12),

          // Chart area dengan tinggi responsif
          Container(
            height: isMobileLandscape ? 120 : (isLandscape ? 160 : 180),
            child: spots.isEmpty
                ? _buildEmptyChartState(
                    caloriesTarget, timeRange, isMobileLandscape)
                : _buildChart(spots, labels, minY, maxY, averageCalories,
                    dashboardProvider),
          ),

          // Legend responsif - sembunyikan di mobile landscape untuk save space
          if (spots.isNotEmpty && !isMobileLandscape)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  _buildLegendItem(
                    color: AppColors.primary,
                    label: 'Consumed',
                  ),
                  if (averageCalories > 0)
                    _buildLegendItem(
                      color: Colors.orange,
                      label: 'Average',
                      isDashed: true,
                    ),
                  if (caloriesTarget > 0)
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

  Widget _buildEmptyChartState(
      double caloriesTarget, String timeRange, bool isMobileLandscape) {
    final String timeText = timeRange == 'week' ? 'week' : 'month';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: isMobileLandscape ? 32 : 40,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'No calorie data this $timeText',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: isMobileLandscape ? 12 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (caloriesTarget > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Target: ${caloriesTarget.toStringAsFixed(0)} kcal/day',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: isMobileLandscape ? 10 : 12,
              ),
            ),
          ],
          if (caloriesTarget == 0) ...[
            const SizedBox(height: 4),
            Text(
              'Set your daily calorie target in profile',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: isMobileLandscape ? 10 : 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector(DashboardProvider dashboardProvider) {
    final currentRange = dashboardProvider.timeRange;
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    final isMobileLandscape = isMobile && isLandscape;

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
            isMobileLandscape: isMobileLandscape,
          ),
          _buildTimeRangeButton(
            text: 'Month',
            isSelected: currentRange == 'month',
            onTap: () => dashboardProvider.changeTimeRange('month'),
            isMobileLandscape: isMobileLandscape,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isMobileLandscape,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: isMobileLandscape ? 8 : 12,
            vertical: isMobileLandscape ? 4 : 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(isMobileLandscape ? 8 : 12),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: isMobileLandscape ? 10 : 12,
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
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    final isMobileLandscape = isMobile && isLandscape;

    if (nutritionSummary == null) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      padding: EdgeInsets.all(isMobileLandscape ? 10 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Nutrition Recommendation',
            style: TextStyle(
                fontSize: isMobileLandscape ? 14 : 16,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: isMobileLandscape ? 8 : 16),

          // Layout responsive untuk nutrisi - Grid untuk mobile landscape
          if (isMobileLandscape)
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      // Calories
                      _buildCompactNutrientRow(
                        icon: Icons.local_fire_department_outlined,
                        title: 'Calories',
                        min: nutritionSummary.calories.min,
                        max: nutritionSummary.calories.max,
                        unit: 'kcal',
                        color: AppColors.accent1,
                      ),
                      const SizedBox(height: 8),
                      // Protein
                      _buildCompactNutrientRow(
                        icon: Icons.fitness_center_outlined,
                        title: 'Protein',
                        min: nutritionSummary.protein.min,
                        max: nutritionSummary.protein.max,
                        unit: nutritionSummary.protein.unit,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      // Carbs
                      _buildCompactNutrientRow(
                        icon: Icons.grain_outlined,
                        title: 'Carbohydrate',
                        min: nutritionSummary.carbohydrate.min,
                        max: nutritionSummary.carbohydrate.max,
                        unit: nutritionSummary.carbohydrate.unit,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(height: 8),
                      // Fat
                      _buildCompactNutrientRow(
                        icon: Icons.opacity_outlined,
                        title: 'Fat',
                        min: nutritionSummary.fat.min,
                        max: nutritionSummary.fat.max,
                        unit: nutritionSummary.fat.unit,
                        color: Colors.amber,
                      ),
                    ],
                  ),
                ),
              ],
            )
          else ...[
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
        ],
      ),
    );
  }

  Widget _buildCompactNutrientRow({
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
              Text(
                '$min-$max $unit',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
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
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    final isMobileLandscape = isMobile && isLandscape;

    return GlassCard(
      padding: EdgeInsets.symmetric(
          vertical: isMobileLandscape ? 8 : 12,
          horizontal: isMobileLandscape ? 12 : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(
            title: 'BMI',
            value: bmi > 0 ? bmi.toStringAsFixed(1) : '-',
            icon: Icons.monitor_weight_outlined,
            color: AppColors.primary,
            isMobileLandscape: isMobileLandscape,
          ),
          _buildDivider(isMobileLandscape: isMobileLandscape),
          _buildStatItem(
            title: 'Status',
            value:
                status != 'UNKNOWN' && bmi > 0 ? _formatBmiStatus(status) : '-',
            icon: Icons.check_circle_outline,
            color: _getBmiStatusColor(status),
            isMobileLandscape: isMobileLandscape,
          ),
          _buildDivider(isMobileLandscape: isMobileLandscape),
          _buildStatItem(
            title: 'Cal. Need',
            value: caloriesNeed > 0 ? caloriesNeed.toString() : '-',
            icon: Icons.local_fire_department_outlined,
            color: AppColors.accent1,
            isMobileLandscape: isMobileLandscape,
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
    bool isMobileLandscape = false,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: isMobileLandscape ? 16 : 20),
        SizedBox(height: isMobileLandscape ? 2 : 4),
        Text(
          value,
          style: TextStyle(
              fontSize: isMobileLandscape ? 12 : 16,
              fontWeight: FontWeight.bold),
        ),
        Text(
          title,
          style: TextStyle(
              fontSize: isMobileLandscape ? 10 : 12,
              color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildDivider({bool isMobileLandscape = false}) {
    return Container(
      height: isMobileLandscape ? 30 : 40,
      width: 1,
      color: Colors.grey.shade300,
    );
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
    return Column(
      children: [
        // Grafik calories tracker full width
        _buildCaloriesTracker(dashboardProvider),
        const SizedBox(height: 16),

        // BMI dan Food cards di bawah grafik
        _buildActionCards(),
        const SizedBox(height: 16),

        // Bottom stats
        _buildBottomStats(dashboardProvider),
        const SizedBox(height: 16),

        // Nutrition summary
        _buildNutritionSummary(dashboardProvider),
      ],
    );
  }

  Widget _buildMobileLayout(DashboardProvider dashboardProvider) {
    return Column(
      children: [
        _buildCaloriesTracker(dashboardProvider),
        const SizedBox(height: 16),
        _buildActionCards(),
        const SizedBox(height: 16),
        _buildNutritionSummary(dashboardProvider),
        const SizedBox(height: 16),
        _buildBottomStats(dashboardProvider),
      ],
    );
  }

  Widget _buildChart(
      List<FlSpot> spots,
      List<String> labels,
      double minY,
      double maxY,
      double averageCalories,
      DashboardProvider dashboardProvider) {
    return LineChart(
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
              reservedSize: ResponsiveHelper.getResponsiveValue(
                context,
                mobile: 25,
                tablet: 30,
                desktop: 35,
              ),
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= labels.length ||
                    value.toInt() < 0 ||
                    value != value.toInt()) {
                  return const SizedBox.shrink();
                }

                // Show every nth label based on data length and screen size
                final isLandscape = ResponsiveHelper.isLandscape(context);
                final showInterval = isLandscape
                    ? (labels.length > 10 ? 3 : 2)
                    : (labels.length > 7 ? 2 : 1);

                if (value.toInt() % showInterval != 0) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    labels[value.toInt()],
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(
                        context,
                        baseFontSize: 10,
                        landscapeMultiplier: 0.8,
                      ),
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
              reservedSize: ResponsiveHelper.getResponsiveValue(
                context,
                mobile: 35,
                tablet: 45,
                desktop: 50,
              ),
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '${value.toInt()}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(
                        context,
                        baseFontSize: 10,
                        landscapeMultiplier: 0.8,
                      ),
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
            getTooltipColor: (touchedSpot) => Colors.black87.withOpacity(0.8),
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
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(
                      context,
                      baseFontSize: 12,
                    ),
                  ),
                );
              }).toList();
            },
          ),
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {},
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
                  padding: const EdgeInsets.only(right: 5, bottom: 5),
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(
                      context,
                      baseFontSize: 9,
                    ),
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
                  padding: const EdgeInsets.only(right: 5, top: 5),
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(
                      context,
                      baseFontSize: 9,
                    ),
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
            barWidth: ResponsiveHelper.getResponsiveValue(
              context,
              mobile: 2.5,
              tablet: 3,
              desktop: 3.5,
            ),
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                // Highlight dots that are above target
                final isAboveTarget = dashboardProvider.caloriesTarget > 0 &&
                    spot.y > dashboardProvider.caloriesTarget;

                return FlDotCirclePainter(
                  radius: ResponsiveHelper.getResponsiveValue(
                    context,
                    mobile: 4,
                    tablet: 5,
                    desktop: 6,
                  ),
                  color: isAboveTarget ? Colors.red : AppColors.primary,
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
    );
  }
}
