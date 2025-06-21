import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileLayout;
  final Widget desktopLayout;
  final Widget? tabletLayout;

  const ResponsiveLayout({
    Key? key,
    required this.mobileLayout,
    required this.desktopLayout,
    this.tabletLayout,
  }) : super(key: key);

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return desktopLayout;
        } else if (constraints.maxWidth >= 600) {
          return tabletLayout ?? desktopLayout;
        } else {
          return mobileLayout;
        }
      },
    );
  }
}
