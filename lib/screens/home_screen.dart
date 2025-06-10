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
  // Dummy data untuk grafik
  final List<FlSpot> weeklyCaloriesData = [
    FlSpot(0, 1200), // Sun
    FlSpot(1, 1350), // Mon
    FlSpot(2, 1400), // Tue
    FlSpot(3, 1200), // Wed
    FlSpot(4, 1500), // Thu
    FlSpot(5, 1600), // Fri
    FlSpot(6, 1450), // Sat
  ];

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
                color: AppColors.primary.withValues(alpha: 0.1),
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
                color: AppColors.secondary.withValues(alpha: 0.08),
              ),
            ),
          ),

          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 16),
                _buildStatCards(),
                const SizedBox(height: 24),
                _buildCaloriesTracker(),
                const SizedBox(height: 24),
                _buildActionCards(),
                const SizedBox(height: 16),
                _buildBottomStats(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Hey Ulil",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          'Selamat datang di GoHealth',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(
          child: StatChip(
            title: 'Start Weight',
            value: '55.5 KG',
            color: AppColors.primary.withValues(alpha: 0.08),
            iconData: Icons.monitor_weight_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatChip(
            title: 'Goals',
            value: '60 KG',
            color: AppColors.secondary.withValues(alpha: 0.08),
            iconData: Icons.flag_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatChip(
            title: 'Daily Cal',
            value: '15000',
            color: AppColors.accent1.withValues(alpha: 0.08),
            iconData: Icons.local_fire_department_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildCaloriesTracker() {
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'This Week',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 500,
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
                        final style = TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        );
                        String text;
                        switch (value.toInt()) {
                          case 0:
                            text = 'Sun';
                            break;
                          case 1:
                            text = 'Mon';
                            break;
                          case 2:
                            text = 'Tue';
                            break;
                          case 3:
                            text = 'Wed';
                            break;
                          case 4:
                            text = 'Thu';
                            break;
                          case 5:
                            text = 'Fri';
                            break;
                          case 6:
                            text = 'Sat';
                            break;
                          default:
                            text = '';
                            break;
                        }
                        return Text(text, style: style);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 500,
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
                maxX: 6,
                minY: 0,
                maxY: 2000,
                lineBarsData: [
                  LineChartBarData(
                    spots: weeklyCaloriesData,
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
                          AppColors.primary.withValues(alpha: 0.3),
                          AppColors.primary.withValues(alpha: 0.0),
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

  Widget _buildActionCards() {
    return Row(
      children: [
        Expanded(
          child: ActionGlassCard(
            title: 'IBM',
            subtitle: 'Control Your Weight',
            icon: Icons.monitor_weight_outlined,
            color: AppColors.secondary,
            onTap: () => context.go('/ibm'),
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

  Widget _buildBottomStats() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(
            title: 'IBM',
            value: '20.1',
            icon: Icons.monitor_weight_outlined,
            color: AppColors.primary,
          ),
          _buildDivider(),
          _buildStatItem(
            title: 'Status',
            value: 'Normal',
            icon: Icons.check_circle_outline,
            color: Colors.green,
          ),
          _buildDivider(),
          _buildStatItem(
            title: 'Cal. Need',
            value: '12000',
            icon: Icons.local_fire_department_outlined,
            color: AppColors.accent1,
          ),
        ],
      ),
    );
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
