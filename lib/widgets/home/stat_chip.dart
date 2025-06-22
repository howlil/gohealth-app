import 'package:flutter/material.dart';
import '../glass_card.dart';
import '../../utils/responsive_helper.dart';

class StatChip extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData iconData;

  const StatChip({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    final isMobileLandscape = isMobile && isLandscape;

    return GlassCard(
      padding: EdgeInsets.symmetric(
        horizontal: isMobileLandscape ? 8 : 12,
        vertical: isMobileLandscape ? 6 : 10,
      ),
      color: color.withOpacity(0.05),
      borderColor: color.withOpacity(0.2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isMobileLandscape ? 4 : 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isMobileLandscape ? 4 : 6),
            ),
            child: Icon(
              iconData,
              color: color,
              size: isMobileLandscape ? 12 : 16,
            ),
          ),
          SizedBox(width: isMobileLandscape ? 6 : 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobileLandscape ? 9 : 10,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isMobileLandscape ? 1 : 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobileLandscape ? 11 : 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
