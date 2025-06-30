import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1200;

  // Screen size checks
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  // Orientation checks
  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  // Combined checks
  static bool isMobileLandscape(BuildContext context) =>
      isMobile(context) && isLandscape(context);

  static bool isMobilePortrait(BuildContext context) =>
      isMobile(context) && isPortrait(context);

  static bool isTabletLandscape(BuildContext context) =>
      isTablet(context) && isLandscape(context);

  static bool isTabletPortrait(BuildContext context) =>
      isTablet(context) && isPortrait(context);

  // Get responsive value based on screen size
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  // Get responsive value based on orientation
  static T getOrientationValue<T>(
    BuildContext context, {
    required T portrait,
    required T landscape,
  }) {
    return isLandscape(context) ? landscape : portrait;
  }

  // Get screen dimensions
  static Size getScreenSize(BuildContext context) =>
      MediaQuery.of(context).size;

  static double getScreenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double getScreenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // Safe area
  static EdgeInsets getSafeAreaPadding(BuildContext context) =>
      MediaQuery.of(context).padding;

  // Get adaptive padding
  static EdgeInsets getAdaptivePadding(BuildContext context) {
    final isLandscapeMode = isLandscape(context);

    return EdgeInsets.symmetric(
      horizontal: getResponsiveValue(
        context,
        mobile: isLandscapeMode ? 32.0 : 24.0,
        tablet: isLandscapeMode ? 64.0 : 48.0,
        desktop: isLandscapeMode ? 96.0 : 72.0,
      ),
      vertical: getResponsiveValue(
        context,
        mobile: isLandscapeMode ? 16.0 : 24.0,
        tablet: isLandscapeMode ? 24.0 : 32.0,
        desktop: isLandscapeMode ? 32.0 : 48.0,
      ),
    );
  }

  // Get adaptive font size
  static double getAdaptiveFontSize(
    BuildContext context, {
    required double baseFontSize,
    double? landscapeMultiplier,
    double? tabletMultiplier,
    double? desktopMultiplier,
  }) {
    double fontSize = baseFontSize;

    // Apply device type multiplier
    if (isDesktop(context)) {
      fontSize *= desktopMultiplier ?? 1.2;
    } else if (isTablet(context)) {
      fontSize *= tabletMultiplier ?? 1.1;
    }

    // Apply orientation multiplier
    if (isLandscape(context)) {
      fontSize *= landscapeMultiplier ?? 0.9;
    }

    return fontSize;
  }

  // Get adaptive spacing
  static double getAdaptiveSpacing(
    BuildContext context, {
    required double baseSpacing,
    double? landscapeMultiplier,
    double? tabletMultiplier,
    double? desktopMultiplier,
  }) {
    double spacing = baseSpacing;

    // Apply device type multiplier
    if (isDesktop(context)) {
      spacing *= desktopMultiplier ?? 1.5;
    } else if (isTablet(context)) {
      spacing *= tabletMultiplier ?? 1.2;
    }

    // Apply orientation multiplier for mobile
    if (isMobile(context) && isLandscape(context)) {
      spacing *= landscapeMultiplier ?? 0.7;
    }

    return spacing;
  }

  // Check if keyboard is visible
  static bool isKeyboardVisible(BuildContext context) =>
      MediaQuery.of(context).viewInsets.bottom > 0;

  // Get available height excluding keyboard
  static double getAvailableHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom -
        mediaQuery.viewInsets.bottom;
  }
}

// Widget untuk layout responsif berdasarkan orientasi
class OrientationLayout extends StatelessWidget {
  final Widget portrait;
  final Widget landscape;

  const OrientationLayout({
    Key? key,
    required this.portrait,
    required this.landscape,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return orientation == Orientation.portrait ? portrait : landscape;
      },
    );
  }
}

// Widget untuk layout adaptif berdasarkan ukuran layar dan orientasi
class AdaptiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints)
      builder;

  const AdaptiveLayout({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return builder(context, constraints);
      },
    );
  }
}
