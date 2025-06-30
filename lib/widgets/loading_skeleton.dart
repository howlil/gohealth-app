import 'package:flutter/material.dart';

class LoadingSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const LoadingSkeleton({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? Colors.grey.shade300;
    final highlightColor = widget.highlightColor ?? Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor.withValues(alpha: _animation.value),
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

// ============================
// SKELETON WIDGETS FOR VARIOUS UI COMPONENTS
// ============================

class FoodItemSkeleton extends StatelessWidget {
  const FoodItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const LoadingSkeleton(
            width: 40,
            height: 40,
            borderRadius: 8,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 4),
                LoadingSkeleton(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: 12,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const LoadingSkeleton(
            width: 24,
            height: 24,
            borderRadius: 12,
          ),
        ],
      ),
    );
  }
}

// Home Dashboard Skeleton
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header greeting skeleton
          const LoadingSkeleton(height: 28, borderRadius: 6),
          const SizedBox(height: 4),
          LoadingSkeleton(
            width: MediaQuery.of(context).size.width * 0.6,
            height: 16,
            borderRadius: 4,
          ),
          const SizedBox(height: 24),

          // Stats cards grid skeleton
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: List.generate(4, (index) => _buildStatCardSkeleton()),
          ),
          const SizedBox(height: 24),

          // Section title skeleton
          const LoadingSkeleton(height: 20, borderRadius: 6),
          const SizedBox(height: 16),

          // Action cards skeleton
          ...List.generate(
              3,
              (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildActionCardSkeleton(),
                  )),
        ],
      ),
    );
  }

  Widget _buildStatCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LoadingSkeleton(width: 24, height: 24, borderRadius: 12),
              const Spacer(),
              LoadingSkeleton(width: 40, height: 12, borderRadius: 6),
            ],
          ),
          const SizedBox(height: 12),
          const LoadingSkeleton(height: 24, borderRadius: 6),
          const SizedBox(height: 4),
          LoadingSkeleton(width: 60, height: 12, borderRadius: 4),
        ],
      ),
    );
  }

  Widget _buildActionCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const LoadingSkeleton(width: 48, height: 48, borderRadius: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton(width: 120, height: 16, borderRadius: 4),
                const SizedBox(height: 4),
                LoadingSkeleton(width: 180, height: 12, borderRadius: 4),
              ],
            ),
          ),
          const LoadingSkeleton(width: 24, height: 24, borderRadius: 4),
        ],
      ),
    );
  }
}

// Notification List Skeleton
class NotificationListSkeleton extends StatelessWidget {
  final int itemCount;

  const NotificationListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildNotificationItemSkeleton(),
    );
  }

  Widget _buildNotificationItemSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LoadingSkeleton(width: 40, height: 40, borderRadius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: LoadingSkeleton(
                          width: 150, height: 14, borderRadius: 4),
                    ),
                    const LoadingSkeleton(width: 8, height: 8, borderRadius: 4),
                  ],
                ),
                const SizedBox(height: 6),
                LoadingSkeleton(
                    width: double.infinity, height: 12, borderRadius: 4),
                const SizedBox(height: 4),
                LoadingSkeleton(width: 180, height: 12, borderRadius: 4),
                const SizedBox(height: 8),
                Row(
                  children: [
                    LoadingSkeleton(width: 60, height: 12, borderRadius: 6),
                    const Spacer(),
                    LoadingSkeleton(width: 50, height: 10, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const LoadingSkeleton(width: 18, height: 18, borderRadius: 9),
        ],
      ),
    );
  }
}

// Profile Page Skeleton
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile header
          Container(
            width: double.infinity,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 24),
                const LoadingSkeleton(width: 80, height: 80, borderRadius: 40),
                const SizedBox(height: 12),
                LoadingSkeleton(width: 120, height: 18, borderRadius: 6),
                const SizedBox(height: 4),
                LoadingSkeleton(width: 150, height: 14, borderRadius: 4),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Profile form
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFormSectionSkeleton(),
                const SizedBox(height: 16),
                _buildFormSectionSkeleton(small: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSectionSkeleton({bool small = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingSkeleton(width: 120, height: 18, borderRadius: 6),
          const SizedBox(height: 16),
          if (!small) ...[
            ...List.generate(
                5,
                (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LoadingSkeleton(
                              width: 80, height: 12, borderRadius: 4),
                          const SizedBox(height: 6),
                          LoadingSkeleton(height: 50, borderRadius: 25),
                        ],
                      ),
                    )),
            LoadingSkeleton(height: 50, borderRadius: 25),
          ] else ...[
            LoadingSkeleton(height: 50, borderRadius: 25),
          ],
        ],
      ),
    );
  }
}

// BMI History Skeleton
class BMIHistorySkeleton extends StatelessWidget {
  final int itemCount;

  const BMIHistorySkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (context, index) =>
          Divider(color: Colors.grey.shade200),
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingSkeleton(width: 80, height: 14, borderRadius: 4),
                  const SizedBox(height: 4),
                  LoadingSkeleton(width: 60, height: 12, borderRadius: 4),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                LoadingSkeleton(width: 40, height: 16, borderRadius: 4),
                const SizedBox(height: 4),
                LoadingSkeleton(width: 50, height: 12, borderRadius: 6),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Nutrition Summary Skeleton
class NutritionSummarySkeleton extends StatelessWidget {
  const NutritionSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        LoadingSkeleton(width: 150, height: 20, borderRadius: 6),
        const SizedBox(height: 16),

        // Calorie card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LoadingSkeleton(width: 80, height: 14, borderRadius: 4),
                  LoadingSkeleton(width: 60, height: 12, borderRadius: 4),
                ],
              ),
              const SizedBox(height: 16),
              LoadingSkeleton(height: 100, borderRadius: 50),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                    3,
                    (index) => Column(
                          children: [
                            LoadingSkeleton(
                                width: 40, height: 16, borderRadius: 4),
                            const SizedBox(height: 4),
                            LoadingSkeleton(
                                width: 30, height: 12, borderRadius: 4),
                          ],
                        )),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Nutrition bars
        ...List.generate(
            3,
            (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            LoadingSkeleton(
                                width: 80, height: 14, borderRadius: 4),
                            LoadingSkeleton(
                                width: 50, height: 12, borderRadius: 4),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LoadingSkeleton(height: 8, borderRadius: 4),
                      ],
                    ),
                  ),
                )),
      ],
    );
  }
}
