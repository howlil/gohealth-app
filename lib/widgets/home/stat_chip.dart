import 'package:flutter/material.dart';
import '../glass_card.dart';

class StatChip extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData iconData;
  final VoidCallback? onTap;

  const StatChip({
    Key? key,
    required this.title,
    required this.value,
    required this.color,
    required this.iconData,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      color: color.withOpacity(0.05),
      borderColor: color.withOpacity(0.1),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                iconData,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}