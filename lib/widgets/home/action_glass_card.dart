import 'package:flutter/material.dart';
import '../glass_card.dart';
import '../../utils/responsive_helper.dart';

class ActionGlassCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ActionGlassCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    final isMobileLandscape = isMobile && isLandscape;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: EdgeInsets.all(isMobileLandscape ? 10 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isMobileLandscape ? 8 : 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(isMobileLandscape ? 10 : 12),
              ),
              child: Icon(
                icon,
                color: color,
                size: isMobileLandscape ? 18 : 24,
              ),
            ),
            SizedBox(height: isMobileLandscape ? 8 : 12),
            Text(
              title,
              style: TextStyle(
                fontSize: isMobileLandscape ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: isMobileLandscape ? 2 : 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: isMobileLandscape ? 11 : 12,
                color: Colors.grey.shade600,
              ),
              maxLines: isMobileLandscape ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class ComingSoonGlassCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const ComingSoonGlassCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    final isMobileLandscape = isMobile && isLandscape;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: EdgeInsets.all(isMobileLandscape ? 10 : 16),
        color: Colors.grey.shade50.withOpacity(0.7),
        borderColor: Colors.grey.shade300.withOpacity(0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isMobileLandscape ? 8 : 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade400.withOpacity(0.15),
                borderRadius:
                    BorderRadius.circular(isMobileLandscape ? 10 : 12),
              ),
              child: Icon(
                icon,
                color: Colors.grey.shade500,
                size: isMobileLandscape ? 18 : 24,
              ),
            ),
            SizedBox(height: isMobileLandscape ? 8 : 12),
            Text(
              title,
              style: TextStyle(
                fontSize: isMobileLandscape ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: isMobileLandscape ? 2 : 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: isMobileLandscape ? 11 : 12,
                color: Colors.grey.shade500,
              ),
              maxLines: isMobileLandscape ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
