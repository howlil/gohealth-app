import 'package:flutter/material.dart';
import '../../../models/profile_stats.dart';

class ProfileStatsCard extends StatelessWidget {
  final ProfileStats stats;

  const ProfileStatsCard({
    Key? key,
    required this.stats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  context,
                  Icons.fitness_center,
                  stats.totalWorkouts.toString(),
                  'Workouts',
                ),
                _buildStatItem(
                  context,
                  Icons.local_fire_department,
                  '${stats.totalCaloriesBurned}',
                  'Calories',
                ),
                _buildStatItem(
                  context,
                  Icons.timer,
                  '${stats.totalMinutesExercised}',
                  'Minutes',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  context,
                  Icons.trending_up,
                  '${stats.averageCaloriesPerWorkout.round()}',
                  'Avg. Calories',
                ),
                _buildStatItem(
                  context,
                  Icons.access_time,
                  '${stats.averageMinutesPerWorkout.round()}',
                  'Avg. Minutes',
                ),
                _buildStatItem(
                  context,
                  Icons.whatshot,
                  stats.streakDays.toString(),
                  'Streak Days',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
