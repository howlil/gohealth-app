import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/activity_provider.dart';
import '../models/activity_model.dart' as model;
import '../models/activity_plan_model.dart';
import '../utils/app_colors.dart';
import '../utils/responsive_helper.dart';
import '../utils/snackbar_util.dart';
import '../widgets/navigations/app_layout.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/glass_card.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;

  final List<String> _tabs = ['📊 Ringkasan', '🏃 Aktivitas', '📅 Rencana'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController();

    // Initialize data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final isMobileLandscape = ResponsiveHelper.isMobileLandscape(context);

    return AppLayout(
      title: 'Aktivitas & Rencana',
      backgroundColor: const Color(0xFFF8F9FA),
      showBackButton: true,
      currentIndex: 3, // Assuming this is the 4th tab
      child: Column(
        children: [
          // Custom Tab Bar
          Container(
            margin: EdgeInsets.all(isTablet ? 24 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: AppColors.primary,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isMobileLandscape ? 12 : 14,
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: isMobileLandscape ? 12 : 14,
              ),
              onTap: (index) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              tabs: _tabs.map((title) => Tab(text: title)).toList(),
            ),
          ),

          // Page Content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                _tabController.animateTo(index);
              },
              children: [
                _buildSummaryTab(),
                _buildActivitiesTab(),
                _buildPlansTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return Consumer<ActivityProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildLoadingSkeleton();
        }

        return RefreshIndicator(
          onRefresh: provider.refreshAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Selector
                _buildDateSelector(provider),
                const SizedBox(height: 16),

                // Daily Summary Cards
                _buildDailySummaryCards(provider),
                const SizedBox(height: 16),

                // Activity Categories Chart
                _buildActivityCategoriesChart(provider),
                const SizedBox(height: 16),

                // Next Scheduled Activity
                _buildNextScheduledActivity(provider),
                const SizedBox(height: 16),

                // Recent Activities
                _buildRecentActivities(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivitiesTab() {
    return Consumer<ActivityProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Add Activity Button
            Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _showAddActivityDialog(context, provider),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Aktivitas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Activities List
            Expanded(
              child: provider.isLoading
                  ? _buildLoadingSkeleton()
                  : RefreshIndicator(
                      onRefresh: provider.refreshAll,
                      child: provider.activities.isEmpty
                          ? _buildEmptyState(
                              icon: Icons.directions_run,
                              title: 'Belum Ada Aktivitas',
                              subtitle:
                                  'Mulai catat aktivitas harian Anda untuk tracking yang lebih baik',
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: provider.activities.length,
                              itemBuilder: (context, index) {
                                final activity = provider.activities[index];
                                return _buildActivityCard(activity, provider);
                              },
                            ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlansTab() {
    return Consumer<ActivityProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Add Plan Button
            Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _showAddPlanDialog(context, provider),
                icon: const Icon(Icons.add_chart),
                label: const Text('Buat Rencana Aktivitas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Plans List
            Expanded(
              child: provider.isLoadingPlans
                  ? _buildLoadingSkeleton()
                  : RefreshIndicator(
                      onRefresh: provider.refreshAll,
                      child: provider.activityPlans.isEmpty
                          ? _buildEmptyState(
                              icon: Icons.calendar_month,
                              title: 'Belum Ada Rencana',
                              subtitle:
                                  'Buat rencana aktivitas untuk mengatur jadwal latihan Anda',
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: provider.activityPlans.length,
                              itemBuilder: (context, index) {
                                final plan = provider.activityPlans[index];
                                return _buildPlanCard(plan, provider);
                              },
                            ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateSelector(ActivityProvider provider) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Tanggal:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(provider),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDisplayDate(provider.selectedDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummaryCards(ActivityProvider provider) {
    final summary = provider.dailySummary;
    final todayActivities =
        provider.getActivitiesForDate(provider.selectedDate);

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Aktivitas',
            value: '${todayActivities.length}',
            icon: Icons.fitness_center,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: 'Kalori Terbakar',
            value: '${summary?.totalCaloriesBurned ?? 0}',
            icon: Icons.local_fire_department,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: 'Durasi (menit)',
            value: '${summary?.totalDuration ?? 0}',
            icon: Icons.timer,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Continue with other build methods...
  Widget _buildActivityCategoriesChart(ActivityProvider provider) {
    final categoriesCount = provider.getActivityCountByCategory();

    if (categoriesCount.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Aktivitas per Kategori',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...categoriesCount.entries.map((entry) {
              final color = _getCategoryColor(entry.key);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getCategoryDisplayName(entry.key),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '${entry.value}x',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNextScheduledActivity(ActivityProvider provider) {
    final nextActivity = provider.nextScheduledActivity;

    if (nextActivity == null) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Aktivitas Selanjutnya',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nextActivity.activityType.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${nextActivity.scheduledTime} • ${nextActivity.plannedDuration} menit',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _startActivity(nextActivity),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Mulai'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities(ActivityProvider provider) {
    final recentActivities = provider.activities.take(5).toList();

    if (recentActivities.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Aktivitas Terbaru',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recentActivities.map((activity) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(activity.activityType.category)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(activity.activityType.category),
                        color:
                            _getCategoryColor(activity.activityType.category),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.activityType.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${activity.duration} menit • ${activity.caloriesBurned} kalori',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatDisplayDate(activity.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(
      model.Activity activity, ActivityProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(activity.activityType.category)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(activity.activityType.category),
                    color: _getCategoryColor(activity.activityType.category),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.activityType.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _getCategoryDisplayName(activity.activityType.category),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editActivity(activity, provider);
                    } else if (value == 'delete') {
                      _deleteActivity(activity, provider);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildActivityInfoItem(
                  Icons.timer,
                  '${activity.duration} menit',
                ),
                const SizedBox(width: 16),
                _buildActivityInfoItem(
                  Icons.local_fire_department,
                  '${activity.caloriesBurned} kalori',
                ),
                const SizedBox(width: 16),
                _buildActivityInfoItem(
                  Icons.date_range,
                  _formatDisplayDate(activity.date),
                ),
              ],
            ),
            if (activity.notes != null && activity.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                activity.notes!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(ActivityPlan plan, ActivityProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: plan.isActive
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    plan.isActive ? 'Aktif' : 'Tidak Aktif',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: plan.isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editPlan(plan, provider);
                        break;
                      case 'toggle':
                        _togglePlanStatus(plan, provider);
                        break;

                      case 'delete':
                        _deletePlan(plan, provider);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            plan.isActive ? Icons.pause : Icons.play_arrow,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(plan.isActive ? 'Nonaktifkan' : 'Aktifkan'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              plan.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (plan.description != null) ...[
              const SizedBox(height: 4),
              Text(
                plan.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _buildActivityInfoItem(
                  Icons.date_range,
                  '${_formatDisplayDate(plan.startDate)} - ${plan.endDate != null ? _formatDisplayDate(plan.endDate!) : "∞"}',
                ),
                const SizedBox(width: 16),
                _buildActivityInfoItem(
                  Icons.fitness_center,
                  '${plan.plannedActivities.length} aktivitas',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          5,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LoadingSkeleton(
              width: double.infinity,
              height: 80,
              borderRadius: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog and Action Methods
  Future<void> _selectDate(ActivityProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _parseDate(provider.selectedDate),
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
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate = _formatDateToDDMMYYYY(picked);
      await provider.updateSelectedDate(formattedDate);
    }
  }

  void _showAddActivityDialog(BuildContext context, ActivityProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _AddActivityDialog(provider: provider),
    );
  }

  void _showAddPlanDialog(BuildContext context, ActivityProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _AddPlanDialog(provider: provider),
    );
  }

  void _editActivity(model.Activity activity, ActivityProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _EditActivityDialog(
        activity: activity,
        provider: provider,
      ),
    );
  }

  void _deleteActivity(model.Activity activity, ActivityProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Aktivitas'),
        content: Text(
          'Apakah Anda yakin ingin menghapus aktivitas "${activity.activityType.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success =
                  await provider.deleteActivity(activity.activityTypeId);
              if (mounted) {
                if (success) {
                  SnackbarUtil.showSuccess(
                      context, 'Aktivitas berhasil dihapus');
                } else {
                  SnackbarUtil.showError(
                      context, provider.error ?? 'Gagal menghapus aktivitas');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editPlan(ActivityPlan plan, ActivityProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _EditPlanDialog(
        plan: plan,
        provider: provider,
      ),
    );
  }

  void _togglePlanStatus(ActivityPlan plan, ActivityProvider provider) async {
    final success = plan.isActive
        ? await provider.deactivateActivityPlan(plan.id)
        : await provider.activateActivityPlan(plan.id);

    if (mounted) {
      if (success) {
        SnackbarUtil.showSuccess(
          context,
          plan.isActive
              ? 'Rencana berhasil dinonaktifkan'
              : 'Rencana berhasil diaktifkan',
        );
      } else {
        SnackbarUtil.showError(
            context, provider.error ?? 'Gagal mengubah status rencana');
      }
    }
  }

  void _deletePlan(ActivityPlan plan, ActivityProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Rencana'),
        content: Text(
          'Apakah Anda yakin ingin menghapus rencana "${plan.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await provider.deleteActivityPlan(plan.id);
              if (mounted) {
                if (success) {
                  SnackbarUtil.showSuccess(context, 'Rencana berhasil dihapus');
                } else {
                  SnackbarUtil.showError(
                      context, provider.error ?? 'Gagal menghapus rencana');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _startActivity(ScheduledActivity scheduledActivity) {
    final provider = context.read<ActivityProvider>();
    showDialog(
      context: context,
      builder: (context) => _StartActivityDialog(
        scheduledActivity: scheduledActivity,
        provider: provider,
      ),
    );
  }

  // Helper Methods
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'CARDIO':
        return Colors.red;
      case 'STRENGTH':
        return Colors.blue;
      case 'FLEXIBILITY':
        return Colors.green;
      case 'SPORTS':
        return Colors.orange;
      case 'DAILY':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'CARDIO':
        return Icons.favorite;
      case 'STRENGTH':
        return Icons.fitness_center;
      case 'FLEXIBILITY':
        return Icons.self_improvement;
      case 'SPORTS':
        return Icons.sports;
      case 'DAILY':
        return Icons.home;
      default:
        return Icons.directions_run;
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'CARDIO':
        return 'Kardio';
      case 'STRENGTH':
        return 'Kekuatan';
      case 'FLEXIBILITY':
        return 'Fleksibilitas';
      case 'SPORTS':
        return 'Olahraga';
      case 'DAILY':
        return 'Harian';
      default:
        return category;
    }
  }

  String _formatDisplayDate(String dateString) {
    try {
      final date = _parseDate(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  DateTime _parseDate(String dateString) {
    try {
      return DateFormat('dd-MM-yyyy').parse(dateString);
    } catch (e) {
      return DateTime.now();
    }
  }

  String _formatDateToDDMMYYYY(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }
}

// Additional Dialog Widgets will be implemented separately for better organization
class _AddActivityDialog extends StatefulWidget {
  final ActivityProvider provider;

  const _AddActivityDialog({required this.provider});

  @override
  State<_AddActivityDialog> createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<_AddActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _notesController = TextEditingController();

  model.ActivityType? _selectedActivityType;
  String _selectedIntensity = 'MODERATE';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _intensityOptions = ['LOW', 'MODERATE', 'HIGH'];

  @override
  void initState() {
    super.initState();
    _selectedDate = _parseDate(widget.provider.selectedDate);
  }

  @override
  void dispose() {
    _durationController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DateTime _parseDate(String dateString) {
    try {
      return DateFormat('dd-MM-yyyy').parse(dateString);
    } catch (e) {
      return DateTime.now();
    }
  }

  String _formatDateToDDMMYYYY(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  String _getIntensityDisplayName(String intensity) {
    switch (intensity) {
      case 'LOW':
        return 'Rendah';
      case 'MODERATE':
        return 'Sedang';
      case 'HIGH':
        return 'Tinggi';
      default:
        return intensity;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Aktivitas'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Activity Type Dropdown
                DropdownButtonFormField<model.ActivityType>(
                  value: _selectedActivityType,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Aktivitas',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.provider.activityTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedActivityType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Pilih jenis aktivitas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date Picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 7)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child:
                        Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                  ),
                ),
                const SizedBox(height: 16),

                // Duration
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Durasi (menit)',
                    border: OutlineInputBorder(),
                    suffixText: 'menit',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan durasi aktivitas';
                    }
                    final duration = int.tryParse(value);
                    if (duration == null || duration <= 0) {
                      return 'Durasi harus berupa angka positif';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Calories Burned (Optional)
                TextFormField(
                  controller: _caloriesController,
                  decoration: const InputDecoration(
                    labelText: 'Kalori Terbakar (opsional)',
                    border: OutlineInputBorder(),
                    suffixText: 'kcal',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final calories = int.tryParse(value);
                      if (calories == null || calories < 0) {
                        return 'Kalori harus berupa angka positif';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Intensity
                DropdownButtonFormField<String>(
                  value: _selectedIntensity,
                  decoration: const InputDecoration(
                    labelText: 'Intensitas',
                    border: OutlineInputBorder(),
                  ),
                  items: _intensityOptions.map((intensity) {
                    return DropdownMenuItem(
                      value: intensity,
                      child: Text(_getIntensityDisplayName(intensity)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedIntensity = value ?? 'MODERATE';
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitActivity,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _submitActivity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final duration = int.parse(_durationController.text);
      final calories = _caloriesController.text.isNotEmpty
          ? int.parse(_caloriesController.text)
          : null;

      final request = model.CreateActivityRequest(
        activityTypeId: _selectedActivityType!.id,
        date: _formatDateToDDMMYYYY(_selectedDate),
        duration: duration,
        caloriesBurned: calories,
        intensity: _selectedIntensity,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      final success = await widget.provider.createActivity(request);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          SnackbarUtil.showSuccess(context, 'Aktivitas berhasil ditambahkan');
        } else {
          SnackbarUtil.showError(
              context, widget.provider.error ?? 'Gagal menambahkan aktivitas');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtil.showError(context, 'Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _AddPlanDialog extends StatefulWidget {
  final ActivityProvider provider;

  const _AddPlanDialog({required this.provider});

  @override
  State<_AddPlanDialog> createState() => _AddPlanDialogState();
}

class _AddPlanDialogState extends State<_AddPlanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDateToDDMMYYYY(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Buat Rencana Aktivitas'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Plan Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Rencana',
                    border: OutlineInputBorder(),
                    hintText: 'Contoh: Latihan Pagi Rutin',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Masukkan nama rencana';
                    }
                    if (value.trim().length < 2) {
                      return 'Nama rencana minimal 2 karakter';
                    }
                    if (value.trim().length > 100) {
                      return 'Nama rencana maksimal 100 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (opsional)',
                    border: OutlineInputBorder(),
                    hintText:
                        'Jelaskan tujuan atau detail rencana aktivitas Anda',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value != null && value.trim().length > 500) {
                      return 'Deskripsi maksimal 500 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Start Date
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked;
                        // Reset end date if it's before the new start date
                        if (_endDate != null &&
                            _endDate!.isBefore(_startDate)) {
                          _endDate = null;
                        }
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Mulai',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormat('dd MMM yyyy').format(_startDate)),
                  ),
                ),
                const SizedBox(height: 16),

                // End Date (Optional)
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          _endDate ?? _startDate.add(const Duration(days: 30)),
                      firstDate: _startDate,
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (picked != null) {
                      setState(() {
                        _endDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Tanggal Berakhir (opsional)',
                      border: const OutlineInputBorder(),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_endDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                setState(() {
                                  _endDate = null;
                                });
                              },
                            ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                    child: Text(
                      _endDate != null
                          ? DateFormat('dd MMM yyyy').format(_endDate!)
                          : 'Tidak terbatas',
                      style: TextStyle(
                        color: _endDate != null
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Info Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Setelah membuat rencana, Anda dapat menambahkan aktivitas harian ke rencana ini.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitPlan,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Buat Rencana'),
        ),
      ],
    );
  }

  Future<void> _submitPlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final request = CreateActivityPlanRequest(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        startDate: _formatDateToDDMMYYYY(_startDate),
        endDate: _endDate != null ? _formatDateToDDMMYYYY(_endDate!) : null,
      );

      final success = await widget.provider.createActivityPlan(request);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          SnackbarUtil.showSuccess(
              context, 'Rencana aktivitas berhasil dibuat');
        } else {
          SnackbarUtil.showError(context,
              widget.provider.error ?? 'Gagal membuat rencana aktivitas');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtil.showError(context, 'Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _EditActivityDialog extends StatefulWidget {
  final model.Activity activity;
  final ActivityProvider provider;

  const _EditActivityDialog({
    required this.activity,
    required this.provider,
  });

  @override
  State<_EditActivityDialog> createState() => _EditActivityDialogState();
}

class _EditActivityDialogState extends State<_EditActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _notesController = TextEditingController();

  model.ActivityType? _selectedActivityType;
  String _selectedIntensity = 'MODERATE';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _intensityOptions = ['LOW', 'MODERATE', 'HIGH'];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final activity = widget.activity;

    // Set initial values from existing activity
    _selectedDate = _parseDate(activity.date);
    _durationController.text = activity.duration.toString();
    _caloriesController.text = activity.caloriesBurned.toString();
    _notesController.text = activity.notes ?? '';
    _selectedIntensity = activity.intensity ?? 'MODERATE';

    // Find and set the activity type
    _selectedActivityType = widget.provider.activityTypes
        .where((type) => type.id == activity.activityTypeId)
        .firstOrNull;
  }

  @override
  void dispose() {
    _durationController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DateTime _parseDate(String dateString) {
    try {
      return DateFormat('dd-MM-yyyy').parse(dateString);
    } catch (e) {
      return DateTime.now();
    }
  }

  String _formatDateToDDMMYYYY(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  String _getIntensityDisplayName(String intensity) {
    switch (intensity) {
      case 'LOW':
        return 'Rendah';
      case 'MODERATE':
        return 'Sedang';
      case 'HIGH':
        return 'Tinggi';
      default:
        return intensity;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Aktivitas'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Activity Type Dropdown
                DropdownButtonFormField<model.ActivityType>(
                  value: _selectedActivityType,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Aktivitas',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.provider.activityTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedActivityType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Pilih jenis aktivitas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date Picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 7)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child:
                        Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                  ),
                ),
                const SizedBox(height: 16),

                // Duration
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Durasi (menit)',
                    border: OutlineInputBorder(),
                    suffixText: 'menit',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan durasi aktivitas';
                    }
                    final duration = int.tryParse(value);
                    if (duration == null || duration <= 0) {
                      return 'Durasi harus berupa angka positif';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Calories Burned
                TextFormField(
                  controller: _caloriesController,
                  decoration: const InputDecoration(
                    labelText: 'Kalori Terbakar',
                    border: OutlineInputBorder(),
                    suffixText: 'kcal',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan kalori yang terbakar';
                    }
                    final calories = int.tryParse(value);
                    if (calories == null || calories < 0) {
                      return 'Kalori harus berupa angka positif';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Intensity
                DropdownButtonFormField<String>(
                  value: _selectedIntensity,
                  decoration: const InputDecoration(
                    labelText: 'Intensitas',
                    border: OutlineInputBorder(),
                  ),
                  items: _intensityOptions.map((intensity) {
                    return DropdownMenuItem(
                      value: intensity,
                      child: Text(_getIntensityDisplayName(intensity)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedIntensity = value ?? 'MODERATE';
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitEditActivity,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _submitEditActivity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final duration = int.parse(_durationController.text);
      final calories = int.parse(_caloriesController.text);

      final request = model.CreateActivityRequest(
        activityTypeId: _selectedActivityType!.id,
        date: _formatDateToDDMMYYYY(_selectedDate),
        duration: duration,
        caloriesBurned: calories,
        intensity: _selectedIntensity,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      final success = await widget.provider
          .updateActivity(widget.activity.activityTypeId, request);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          SnackbarUtil.showSuccess(context, 'Aktivitas berhasil diperbarui');
        } else {
          SnackbarUtil.showError(
              context, widget.provider.error ?? 'Gagal memperbarui aktivitas');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtil.showError(context, 'Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _EditPlanDialog extends StatefulWidget {
  final ActivityPlan plan;
  final ActivityProvider provider;

  const _EditPlanDialog({
    required this.plan,
    required this.provider,
  });

  @override
  State<_EditPlanDialog> createState() => _EditPlanDialogState();
}

class _EditPlanDialogState extends State<_EditPlanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final plan = widget.plan;

    // Set initial values from existing plan
    _nameController.text = plan.name;
    _descriptionController.text = plan.description ?? '';
    _startDate = _parseDate(plan.startDate);
    _endDate = plan.endDate != null ? _parseDate(plan.endDate!) : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  DateTime _parseDate(String dateString) {
    try {
      return DateFormat('dd-MM-yyyy').parse(dateString);
    } catch (e) {
      return DateTime.now();
    }
  }

  String _formatDateToDDMMYYYY(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Rencana Aktivitas'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Plan Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Rencana',
                    border: OutlineInputBorder(),
                    hintText: 'Contoh: Latihan Pagi Rutin',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Masukkan nama rencana';
                    }
                    if (value.trim().length < 2) {
                      return 'Nama rencana minimal 2 karakter';
                    }
                    if (value.trim().length > 100) {
                      return 'Nama rencana maksimal 100 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (opsional)',
                    border: OutlineInputBorder(),
                    hintText:
                        'Jelaskan tujuan atau detail rencana aktivitas Anda',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value != null && value.trim().length > 500) {
                      return 'Deskripsi maksimal 500 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Start Date
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked;
                        // Reset end date if it's before the new start date
                        if (_endDate != null &&
                            _endDate!.isBefore(_startDate)) {
                          _endDate = null;
                        }
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Mulai',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormat('dd MMM yyyy').format(_startDate)),
                  ),
                ),
                const SizedBox(height: 16),

                // End Date (Optional)
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          _endDate ?? _startDate.add(const Duration(days: 30)),
                      firstDate: _startDate,
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (picked != null) {
                      setState(() {
                        _endDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Tanggal Berakhir (opsional)',
                      border: const OutlineInputBorder(),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_endDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                setState(() {
                                  _endDate = null;
                                });
                              },
                            ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                    child: Text(
                      _endDate != null
                          ? DateFormat('dd MMM yyyy').format(_endDate!)
                          : 'Tidak terbatas',
                      style: TextStyle(
                        color: _endDate != null
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Status Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.plan.isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: widget.plan.isActive
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.plan.isActive
                            ? Icons.check_circle
                            : Icons.pause_circle,
                        color:
                            widget.plan.isActive ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Status: ${widget.plan.isActive ? "Aktif" : "Tidak Aktif"}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitEditPlan,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _submitEditPlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final request = CreateActivityPlanRequest(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        startDate: _formatDateToDDMMYYYY(_startDate),
        endDate: _endDate != null ? _formatDateToDDMMYYYY(_endDate!) : null,
      );

      final success =
          await widget.provider.updateActivityPlan(widget.plan.id, request);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          SnackbarUtil.showSuccess(
              context, 'Rencana aktivitas berhasil diperbarui');
        } else {
          SnackbarUtil.showError(context,
              widget.provider.error ?? 'Gagal memperbarui rencana aktivitas');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtil.showError(context, 'Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _StartActivityDialog extends StatefulWidget {
  final ScheduledActivity scheduledActivity;
  final ActivityProvider provider;

  const _StartActivityDialog({
    required this.scheduledActivity,
    required this.provider,
  });

  @override
  State<_StartActivityDialog> createState() => _StartActivityDialogState();
}

class _StartActivityDialogState extends State<_StartActivityDialog> {
  // Implementation for Start Activity Dialog
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mulai Aktivitas'),
      content: const Text('Dialog untuk mulai aktivitas akan diimplementasi'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}
