import 'package:flutter/material.dart';
import '../../../models/user.dart';
import 'profile_avatar.dart';

class ProfileHeader extends StatelessWidget {
  final User user;
  final VoidCallback onAvatarTap;

  const ProfileHeader({
    Key? key,
    required this.user,
    required this.onAvatarTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Stack(
          children: [
            ProfileAvatar(
              imageUrl:
                  user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
              size: 80,
              onTap: onAvatarTap,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          user.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          user.email,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
