// lib/features/splash_screen.dart (Updated)
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  final List<Animation<Offset>> _bubbleAnimations = [];
  final List<double> _bubbleSizes = [];
  final List<Color> _bubbleColors = [];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _rotationAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6, curve: Curves.easeInOut),
      ),
    );

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

    // Start animation and navigate after completion
    _controller.forward().then((_) {
      _navigateAfterSplash();
    });
  }

  // Navigation logic based on authentication state
  void _navigateAfterSplash() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Check if user is already logged in
      if (authProvider.isLoggedIn) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FFFC),
              Color(0xFFE6F7F0),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ...List.generate(
              _bubbleAnimations.length,
              (index) => AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Positioned(
                    left: MediaQuery.of(context).size.width *
                        _bubbleAnimations[index].value.dx,
                    top: MediaQuery.of(context).size.height *
                        _bubbleAnimations[index].value.dy,
                    child: Container(
                      width: _bubbleSizes[index],
                      height: _bubbleSizes[index],
                      decoration: BoxDecoration(
                        color: _bubbleColors[index],
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 10.0,
                              sigmaY: 10.0,
                            ),
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.8,
                              height: MediaQuery.of(context).size.width * 0.8,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(76),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withAlpha(128),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(13),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.health_and_safety,
                                    size: 100,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 24),
                                  Text(
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
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
