import 'package:flutter/material.dart';
import '../utils/env_config.dart';

class ImageUrlHelper {
  static String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    
    // Check if imagePath is already a full URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    
    // Handle relative paths from the API
    if (imagePath.startsWith('/')) {
      return '${EnvConfig.apiBaseUrl}$imagePath';
    }
    
    // Handle paths without leading slash
    return '${EnvConfig.apiBaseUrl}/$imagePath';
  }
  
  static ImageProvider? getImageProvider(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }
    
    final fullUrl = getFullImageUrl(imagePath);
    if (fullUrl.isEmpty) {
      return null;
    }
    
    return NetworkImage(fullUrl);
  }
  
  static Widget getProfileAvatar({
    String? imageUrl, 
    double size = 50, 
    Color? backgroundColor,
    Widget? placeholder,
  }) {
    final imageProvider = getImageProvider(imageUrl);
    
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor ?? Colors.grey.shade200,
      backgroundImage: imageProvider,
      child: imageProvider == null ? (placeholder ?? Icon(
        Icons.person,
        size: size * 0.6,
        color: Colors.grey.shade500,
      )) : null,
    );
  }
}