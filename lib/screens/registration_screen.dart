import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:gohealth/providers/auth_provider.dart';
import 'package:gohealth/services/registration_service.dart';
import 'package:gohealth/widgets/auth/auth_error_widget.dart';
import 'package:gohealth/widgets/inputs/rounded_input_field.dart';
import 'package:gohealth/widgets/rounded_button.dart';
import 'package:gohealth/utils/app_colors.dart';
import 'package:gohealth/utils/env_config.dart';
import 'package:gohealth/utils/responsive_helper.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();

  String? _gender;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final RegistrationService _registrationService =
      RegistrationService(baseUrl: EnvConfig.apiBaseUrl);

  final List<String> _genderOptions = ['MALE', 'FEMALE', 'OTHER'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        // Check if user is logged in (auto-login successful) or needs manual login
        if (authProvider.isLoggedIn) {
          // Auto-login successful, navigate to home
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registrasi berhasil! Selamat datang di GoHealth!'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/home');
        } else {
          // Registration successful but needs manual login
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  authProvider.error ?? 'Registrasi berhasil! Silakan login.'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/login');
        }
      } else {
        // Registration failed
        setState(() {
          _errorMessage =
              authProvider.error ?? 'Registrasi gagal. Silakan coba lagi.';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Something went wrong. Please try again later.';
      });
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
          SizedBox(height: ResponsiveHelper.getScreenHeight(context) * 0.05),

          // Logo and title section
          _buildLogoSection(),

          SizedBox(height: ResponsiveHelper.getScreenHeight(context) * 0.03),

          // Registration card
          _buildRegistrationCard(),

          SizedBox(
              height: ResponsiveHelper.getAdaptiveSpacing(context,
                  baseSpacing: 30)),

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

          // Right side - Registration form
          Expanded(
            flex: 1,
            child: _buildRegistrationCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    final iconSize = ResponsiveHelper.getResponsiveValue(
      context,
      mobile: ResponsiveHelper.isLandscape(context) ? 70.0 : 100.0,
      tablet: 120.0,
      desktop: 140.0,
    );

    final logoFontSize = ResponsiveHelper.getAdaptiveFontSize(
      context,
      baseFontSize: 36,
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
                  Icons.person_add,
                  size: iconSize * 0.5,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),

        SizedBox(
            height:
                ResponsiveHelper.getAdaptiveSpacing(context, baseSpacing: 20)),

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
          'Bergabung dengan GoHealth',
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

  Widget _buildRegistrationCard() {
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
                  'Buat Akun Baru',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Daftar untuk memulai perjalanan kesehatan Anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withAlpha(153),
                  ),
                ),

                const SizedBox(height: 24),

                // Name field
                RoundedInputField(
                  controller: _nameController,
                  hintText: 'Nama Lengkap',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Silakan masukkan nama Anda';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email field
                RoundedInputField(
                  controller: _emailController,
                  hintText: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Silakan masukkan email Anda';
                    }
                    if (!_registrationService.isEmailValid(value)) {
                      return 'Silakan masukkan email yang valid';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password field
                RoundedInputField(
                  controller: _passwordController,
                  hintText: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: _obscurePassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                  onSuffixIconTap: _togglePasswordVisibility,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Silakan masukkan password';
                    }
                    if (!_registrationService.isPasswordStrong(value)) {
                      return 'Password minimal 8 karakter dengan huruf besar, kecil, angka, dan simbol';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Confirm password field
                RoundedInputField(
                  controller: _confirmPasswordController,
                  hintText: 'Konfirmasi Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: _obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                  onSuffixIconTap: _toggleConfirmPasswordVisibility,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Silakan konfirmasi password';
                    }
                    if (value != _passwordController.text) {
                      return 'Password tidak cocok';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Age field
                RoundedInputField(
                  controller: _ageController,
                  hintText: 'Usia (Opsional)',
                  icon: Icons.calendar_today_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final age = int.tryParse(value);
                      if (age == null) {
                        return 'Silakan masukkan usia yang valid';
                      }
                      if (age < 1 || age > 120) {
                        return 'Usia harus antara 1-120 tahun';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Gender dropdown
                _buildGenderDropdown(),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  AuthErrorWidget(error: _errorMessage!),
                ],

                const SizedBox(height: 24),

                // Register button
                RoundedButton(
                  text: 'Daftar',
                  onPressed: _isLoading ? null : _submitForm,
                  isLoading: _isLoading,
                  width: double.infinity,
                  height: 56,
                  fontSize: 16,
                ),

                const SizedBox(height: 16),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sudah punya akun? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withAlpha(153),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: const Text(
                        'Masuk',
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
          'Dengan mendaftar, Anda menyetujui',
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

  Widget _buildGenderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(179),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.primary.withAlpha(77)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender,
          isExpanded: true,
          hint: Text(
            'Pilih Jenis Kelamin (Opsional)',
            style: TextStyle(
              color: Colors.black.withAlpha(153),
              fontSize: 16,
            ),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: 'MALE',
              child: Text('Laki-laki'),
            ),
            const DropdownMenuItem<String>(
              value: 'FEMALE',
              child: Text('Perempuan'),
            ),
            const DropdownMenuItem<String>(
              value: 'OTHER',
              child: Text('Lainnya'),
            ),
          ],
          onChanged: (String? newValue) {
            setState(() {
              _gender = newValue;
            });
          },
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),
          dropdownColor: Colors.white,
        ),
      ),
    );
  }
}
