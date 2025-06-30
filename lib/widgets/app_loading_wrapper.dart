import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AppLoadingWrapper extends StatelessWidget {
  final Widget child;

  const AppLoadingWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Langsung return child tanpa menampilkan splash screen
    return child;
  }
}
