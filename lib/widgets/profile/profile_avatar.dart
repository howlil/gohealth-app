import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final ImageProvider? imageUrl;
  final double size;
  final VoidCallback? onTap;

  const ProfileAvatar({
    Key? key,
    this.imageUrl,
    this.size = 100,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: imageUrl != null
              ? DecorationImage(
                  image: imageUrl!,
                  fit: BoxFit.cover,
                )
              : null,
          color: Colors.grey[200],
        ),
        child: imageUrl == null
            ? Icon(
                Icons.person,
                size: size * 0.5,
                color: Colors.grey[400],
              )
            : null,
      ),
    );
  }
}
