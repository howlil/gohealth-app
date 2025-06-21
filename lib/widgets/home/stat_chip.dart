import 'package:flutter/material.dart';
import '../glass_card.dart';
import '../../utils/responsive_helper.dart';

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
    final iconSize = ResponsiveHelper.getAdaptiveFontSize(
      context,
      baseFontSize: 18,
      landscapeMultiplier: 0.9,
      tabletMultiplier: 1.1,
    );

    final titleFontSize = ResponsiveHelper.getAdaptiveFontSize(
      context,
      baseFontSize: 12,
      landscapeMultiplier: 0.9,
      tabletMultiplier: 1.1,
    );

    final valueFontSize = ResponsiveHelper.getAdaptiveFontSize(
      context,
      baseFontSize: 16,
      landscapeMultiplier: 0.9,
      tabletMultiplier: 1.1,
    );

    final padding = ResponsiveHelper.isLandscape(context)
        ? const EdgeInsets.symmetric(vertical: 8, horizontal: 8)
        : const EdgeInsets.symmetric(vertical: 12, horizontal: 12);

    return GlassCard(
      padding: padding,
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
                size: iconSize,
              ),
              SizedBox(width: ResponsiveHelper.isLandscape(context) ? 2 : 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.isLandscape(context) ? 2 : 4),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
