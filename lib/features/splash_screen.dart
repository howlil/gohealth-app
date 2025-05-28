import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final List<Animation<Offset>> _bubbleAnimations = [];
  final List<double> _bubbleSizes = [];
  final List<Color> _bubbleColors = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    // Check auth status after animation
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAuthAndNavigate();
      }
    });

    for (int i = 0; i < 12; i++) {
      _bubbleSizes.add(20.0 + (i % 4) * 15);

      // Random colors with health theme
      _bubbleColors.add([
        const Color(0x552ECC71), // Green
        const Color(0x553498DB), // Blue
        const Color(0x55E74C3C), // Red
        const Color(0x55F1C40F), // Yellow
      ][i % 4]);

      // Random animations
      final startPosition = Offset(
        -0.2 + (i / 12) * 1.4,
        1.2 + (i % 4) * 0.1,
      );

      final endPosition = Offset(
        0.1 + (i / 12) * 0.8,
        -0.2 - (i % 3) * 0.1,
      );

      // Fix: Interval stops must be between 0.0 and 1.0
      final startInterval = 0.1 + (i / 20);
      final endInterval =
          math.min(0.7 + (i / 20), 1.0); // Ensure endInterval <= 1.0

      _bubbleAnimations.add(
        Tween<Offset>(
          begin: startPosition,
          end: endPosition,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              startInterval,
              endInterval,
              curve: Curves.easeInOut,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    await ref.read(authProvider.notifier).checkAuthStatus();

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Your app logo or name here
              const Icon(
                Icons.health_and_safety,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'GoHealth',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
