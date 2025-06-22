// lib/features/splash_screen.dart (Updated)
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive_helper.dart';

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

    debugPrint('SplashScreen: initState called');

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Reduced duration
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

    for (int i = 0; i < 8; i++) {
      // Reduced bubble count
      _bubbleSizes.add(15.0 + (i % 3) * 10); // Smaller bubbles

      // Random colors with health theme
      _bubbleColors.add([
        const Color(0x442ECC71), // Green - more transparent
        const Color(0x443498DB), // Blue
        const Color(0x44E74C3C), // Red
        const Color(0x44F1C40F), // Yellow
      ][i % 4]);

      // Random animations
      final startPosition = Offset(
        -0.2 + (i / 8) * 1.4,
        1.2 + (i % 3) * 0.1,
      );

      final endPosition = Offset(
        0.1 + (i / 8) * 0.8,
        -0.2 - (i % 3) * 0.1,
      );

      final startInterval = 0.1 + (i / 20);
      final endInterval = math.min(0.8 + (i / 20), 1.0);

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

    // Start animation
    _controller.forward();

    // Listen to auth provider untuk auto navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToAuthChanges();
    });
  }

  void _listenToAuthChanges() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    debugPrint(
        'SplashScreen: Initial auth check - isLoading: ${authProvider.isLoading}, isLoggedIn: ${authProvider.isLoggedIn}');

    // If not loading anymore, we can proceed
    if (!authProvider.isLoading) {
      debugPrint(
          'SplashScreen: Auth not loading, will navigate after animation');
      _handleNavigationAfterAnimation();
    } else {
      debugPrint('SplashScreen: Auth still loading, waiting...');
      // Wait for auth to finish loading
      _waitForAuthLoad();
    }
  }

  void _waitForAuthLoad() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check periodically if auth loading is done
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        debugPrint(
            'SplashScreen: Checking auth status again - isLoading: ${authProvider.isLoading}');
        if (!authProvider.isLoading) {
          _handleNavigationAfterAnimation();
        } else {
          _waitForAuthLoad(); // Keep waiting
        }
      }
    });
  }

  void _handleNavigationAfterAnimation() {
    // Wait for animation to finish or minimum splash time
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        debugPrint(
            'SplashScreen: Animation finished, navigating - isLoggedIn: ${authProvider.isLoggedIn}');

        // Router will handle the actual navigation via redirect logic
        // We just need to trigger a route change
        if (authProvider.isLoggedIn) {
          debugPrint(
              'SplashScreen: User logged in, router will redirect to home');
        } else {
          debugPrint(
              'SplashScreen: User not logged in, router will redirect to login');
        }
      }
    });
  }

  @override
  void dispose() {
    debugPrint('SplashScreen: dispose called');
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
                              width: ResponsiveHelper.getResponsiveValue(
                                context,
                                mobile: MediaQuery.of(context).size.width * 0.7,
                                tablet: 300,
                                desktop: 350,
                              ),
                              height: ResponsiveHelper.getResponsiveValue(
                                context,
                                mobile: MediaQuery.of(context).size.width * 0.7,
                                tablet: 300,
                                desktop: 350,
                              ),
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
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.health_and_safety,
                                    size: ResponsiveHelper.getResponsiveValue(
                                      context,
                                      mobile: 80,
                                      tablet: 100,
                                      desktop: 120,
                                    ),
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'GoHealth',
                                    style: TextStyle(
                                      fontSize:
                                          ResponsiveHelper.getResponsiveValue(
                                        context,
                                        mobile: 28.0,
                                        tablet: 32.0,
                                        desktop: 36.0,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Kesehatan dalam genggaman',
                                    style: TextStyle(
                                      fontSize:
                                          ResponsiveHelper.getResponsiveValue(
                                        context,
                                        mobile: 12.0,
                                        tablet: 14.0,
                                        desktop: 16.0,
                                      ),
                                      color: Colors.white.withOpacity(0.8),
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

            // Loading indicator at bottom
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Memuat aplikasi...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
