import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/env_config.dart';
import '../utils/responsive_helper.dart';
import '../widgets/rounded_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth/auth_error_widget.dart';
import '../services/login_service.dart';
import '../widgets/inputs/rounded_input_field.dart';

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

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  late final LoginService _loginService;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loginService = LoginService(baseUrl: EnvConfig.apiBaseUrl);

    // Remove auto check - let router handle navigation
    debugPrint('LoginScreen: initState called');
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      debugPrint('Attempting login with email: ${_emailController.text}');

      final success = await authProvider.login(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      debugPrint(
          'Login result: success=$success, isLoggedIn=${authProvider.isLoggedIn}');

      if (success && authProvider.isLoggedIn) {
        // Login berhasil - tampilkan dialog success dulu
        debugPrint('Login successful, showing success dialog');

        await _showSuccessDialog();

        // Setelah dialog ditutup, baru navigate
        if (mounted) {
          debugPrint('Navigating to home after success dialog');
          context.go('/home');
        }
      } else {
        // Login gagal - tampilkan error
        debugPrint('Login failed: ${authProvider.error}');
        setState(() {
          _errorMessage =
              authProvider.error ?? 'Login gagal. Silakan coba lagi.';
        });

        // Tampilkan snackbar untuk error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMessage ?? 'Login gagal'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(10),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Login error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan jaringan. Silakan coba lagi.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_errorMessage ?? 'Terjadi kesalahan'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    return AdaptiveLayout(
      builder: (context, constraints) {
        final isLandscape = ResponsiveHelper.isLandscape(context);

        if (isLandscape) {
          // Landscape layout
          return _buildLandscapeLayout();
        } else {
          // Portrait layout
          return _buildPortraitLayout();
        }
      },
    );
  }

  Widget _buildPortraitLayout() {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Column(
        children: [
          SizedBox(height: ResponsiveHelper.getScreenHeight(context) * 0.1),

          // Logo and title section
          _buildLogoSection(),

          SizedBox(height: ResponsiveHelper.getScreenHeight(context) * 0.05),

          // Login card
          _buildLoginCard(),

          SizedBox(
              height: ResponsiveHelper.getAdaptiveSpacing(context,
                  baseSpacing: 40)),

          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: Row(
        children: [
          // Left side - Logo and title
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogoSection(),
                SizedBox(
                    height: ResponsiveHelper.getAdaptiveSpacing(context,
                        baseSpacing: 20)),
                _buildFooter(),
              ],
            ),
          ),

          SizedBox(
              width: ResponsiveHelper.getAdaptiveSpacing(context,
                  baseSpacing: 32)),

          // Right side - Login form
          Expanded(
            flex: 1,
            child: _buildLoginCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    final iconSize = ResponsiveHelper.getResponsiveValue(
      context,
      mobile: ResponsiveHelper.isLandscape(context) ? 80.0 : 120.0,
      tablet: 140.0,
      desktop: 160.0,
    );

    final logoFontSize = ResponsiveHelper.getAdaptiveFontSize(
      context,
      baseFontSize: 48,
      landscapeMultiplier: 0.8,
      tabletMultiplier: 1.1,
      desktopMultiplier: 1.3,
    );

    final taglineFontSize = ResponsiveHelper.getAdaptiveFontSize(
      context,
      baseFontSize: 16,
      landscapeMultiplier: 0.9,
      tabletMultiplier: 1.1,
      desktopMultiplier: 1.2,
    );

    return Column(
      children: [
        // App icon with glassmorphism effect
        Container(
          width: iconSize,
          height: iconSize,
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
                child: Icon(
                  Icons.favorite,
                  size: iconSize * 0.5,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),

        SizedBox(
            height:
                ResponsiveHelper.getAdaptiveSpacing(context, baseSpacing: 24)),

        // App name
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ).createShader(bounds),
          child: Text(
            'GoHealth',
            style: TextStyle(
              fontSize: logoFontSize,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),

        SizedBox(
            height:
                ResponsiveHelper.getAdaptiveSpacing(context, baseSpacing: 8)),

        // Tagline
        Text(
          'Kesehatan dalam genggaman',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: taglineFontSize,
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
          child: Form(
            key: _formKey,
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

                const SizedBox(height: 32),

                // Email input
                RoundedInputField(
                  controller: _emailController,
                  hintText: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Silakan masukkan email Anda';
                    }
                    if (!value.contains('@')) {
                      return 'Silakan masukkan email yang valid';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password input
                RoundedInputField(
                  controller: _passwordController,
                  hintText: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: !_isPasswordVisible,
                  suffixIcon: _isPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  onSuffixIconTap: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Silakan masukkan password Anda';
                    }
                    if (value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  AuthErrorWidget(error: _errorMessage!),
                ],

                const SizedBox(height: 32),

                // Login button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return RoundedButton(
                      text: 'Masuk',
                      onPressed: _isLoading ? null : _handleEmailLogin,
                      isLoading: _isLoading,
                      width: double.infinity,
                      height: 56,
                      fontSize: 16,
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Belum punya akun? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withAlpha(153),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: const Text(
                        'Daftar',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

  Future<void> _showSuccessDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FFFC),
                  Color(0xFFE6F7F0),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon with animation
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.1),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 50,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                const Text(
                  '🎉 Login Berhasil!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Selamat datang kembali!\nSiap untuk melanjutkan perjalanan kesehatan Anda?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // OK button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Lanjutkan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
