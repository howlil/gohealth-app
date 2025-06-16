import 'package:flutter/material.dart';
import '../../utils/image_url_helper.dart';
import '../../utils/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final ImageProvider? imageUrl;
  final double size;
  final VoidCallback? onTap;
  final bool showEditIcon;
  final Color? backgroundColor;
  final String? imagePath;

  const ProfileAvatar({
    Key? key,
    this.imageUrl,
    this.size = 60,
    this.onTap,
    this.showEditIcon = true,
    this.backgroundColor,
    this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use imageUrl if provided, otherwise use ImageUrlHelper to get from imagePath
    final ImageProvider? effectiveImageProvider = imageUrl ?? 
        (imagePath != null ? ImageUrlHelper.getImageProvider(imagePath) : null);

    return Stack(
      children: [
        // Avatar
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor ?? Colors.grey.shade200,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
              image: effectiveImageProvider != null
                  ? DecorationImage(
                      image: effectiveImageProvider,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: effectiveImageProvider == null
                ? Icon(
                    Icons.person,
                    size: size * 0.6,
                    color: Colors.grey.shade500,
                  )
                : null,
          ),
        ),

        // Edit icon
        if (onTap != null && showEditIcon)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.35,
              height: size * 0.35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                Icons.edit,
                size: size * 0.18,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}