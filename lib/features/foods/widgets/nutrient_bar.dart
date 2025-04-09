import 'package:flutter/material.dart';

class NutrientBar extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final int? percentage;
  final Color color;
  final double maxValue;

  const NutrientBar({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.percentage,
    required this.color,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    // Get progress value between 0 and 1
    final progress = value / maxValue;
    final cappedProgress = progress > 1.0 ? 1.0 : progress;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '${value.toStringAsFixed(1)} $unit',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (percentage != null) ...[
              const SizedBox(width: 4),
              Text(
                '(${percentage}%)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        // Progress bar
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Container(
                height: 8,
                width: MediaQuery.of(context).size.width * 0.7 * cappedProgress,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}