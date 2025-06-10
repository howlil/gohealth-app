import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../widgets/rounded_button.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // Check if already logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = Provider.of<AuthProvider>(context, listen: false);
      if (authState.isLoggedIn) {
        context.go('/home');
      }
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();

    if (!mounted) return;

    if (success) {
      context.go('/home');
    } else if (authProvider.error != null) {
      _showErrorSnackBar(authProvider.error!);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
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
          children: [
            // Background bubbles
            _buildBackgroundBubbles(),

            // Main content
            SafeArea(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildContent(),
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

  Widget _buildBackgroundBubbles() {
    return Stack(
      children: [
        // Top right bubble
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withAlpha(26),
            ),
          ),
        ),
        // Bottom left bubble
        Positioned(
          bottom: -80,
          left: -80,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withAlpha(20),
            ),
          ),
        ),
        // Middle right small bubble
        Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          right: -30,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent1.withAlpha(15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.1),

          // Logo and title section
          _buildLogoSection(),

          SizedBox(height: MediaQuery.of(context).size.height * 0.1),

          // Login card
          _buildLoginCard(),

          const SizedBox(height: 40),

          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // App icon with glassmorphism effect
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(51),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(128),
                  border: Border.all(
                    color: Colors.white.withAlpha(77),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // App name
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ).createShader(bounds),
          child: const Text(
            'GoHealth',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Tagline
        Text(
          'Kesehatan dalam genggaman',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black.withAlpha(153),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(128),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withAlpha(77),
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
            children: [
              // Welcome text
              const Text(
                'Selamat Datang!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Masuk untuk melanjutkan perjalanan kesehatan Anda',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withAlpha(153),
                ),
              ),

              const SizedBox(height: 40),

              // Google sign in button
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return RoundedButton(
                    text: 'Masuk dengan Google',
                    onPressed:
                        authProvider.isLoading ? () {} : _handleGoogleSignIn,
                    color: Colors.white,
                    textColor: Colors.black87,
                    icon: Icons.g_mobiledata,
                    isLoading: authProvider.isLoading,
                    width: double.infinity,
                    height: 56,
                    fontSize: 16,
                  );
                },
              ),

              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.black.withAlpha(26)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'atau',
                      style: TextStyle(
                        color: Colors.black.withAlpha(102),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Colors.black.withAlpha(26)),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Continue as guest
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text(
                  'Lanjutkan sebagai tamu',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'Dengan masuk, Anda menyetujui',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withAlpha(102),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                // Navigate to terms of service
              },
              child: const Text(
                'Syarat & Ketentuan',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Text(
              ' dan ',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withAlpha(102),
              ),
            ),
            GestureDetector(
              onTap: () {
                // Navigate to privacy policy
              },
              child: const Text(
                'Kebijakan Privasi',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
