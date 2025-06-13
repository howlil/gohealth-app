import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gohealth/models/registration_model.dart';
import 'package:gohealth/services/registration_service.dart';
import 'package:gohealth/utils/http_exception.dart';
import 'package:gohealth/widgets/auth/auth_error_widget.dart';
import 'package:gohealth/widgets/inputs/rounded_input_field.dart';
import 'package:gohealth/widgets/rounded_button.dart';
import 'package:gohealth/utils/app_colors.dart';
import 'package:gohealth/utils/env_config.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
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
  void dispose() {
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
      final registrationRequest = RegistrationRequest(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        age: _ageController.text.isNotEmpty
            ? int.parse(_ageController.text)
            : null,
        gender: _gender,
      );

      final response = await _registrationService.register(registrationRequest);

      if (!mounted) return;

      if (response.success) {
        // Registration successful, navigate to login or verification screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to login screen after successful registration using Go Router
        context.go('/login');
      }
    } on HttpException catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
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
      appBar: AppBar(
        title: const Text('Create Account'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Logo or app name
                Center(
                  child: Text(
                    'GoHealth',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ),

                const SizedBox(height: 30),

                // Name field
                RoundedInputField(
                  controller: _nameController,
                  hintText: 'Enter your full name',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email field
                RoundedInputField(
                  controller: _emailController,
                  hintText: 'Enter your email address',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!_registrationService.isEmailValid(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password field
                RoundedInputField(
                  controller: _passwordController,
                  hintText: 'Create a password',
                  icon: Icons.lock,
                  obscureText: _obscurePassword,
                  suffixIcon: _obscurePassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                  onSuffixIconTap: _togglePasswordVisibility,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (!_registrationService.isPasswordStrong(value)) {
                      return 'Password must be at least 8 characters with uppercase, lowercase, number, and special character';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Confirm password field
                RoundedInputField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm your password',
                  icon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: _obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                  onSuffixIconTap: _toggleConfirmPasswordVisibility,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Age field
                RoundedInputField(
                  controller: _ageController,
                  hintText: 'Enter your age',
                  icon: Icons.calendar_today,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final age = int.tryParse(value);
                      if (age == null) {
                        return 'Please enter a valid age';
                      }
                      if (age < 1 || age > 120) {
                        return 'Please enter a valid age between 1 and 120';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Gender dropdown
                _buildGenderDropdown(),

                const SizedBox(height: 24),

                // Error message
                if (_errorMessage != null)
                  AuthErrorWidget(error: _errorMessage!),

                const SizedBox(height: 24),

                // Register button
                RoundedButton(
                  text: 'REGISTER',
                  onPressed: _isLoading ? () {} : _submitForm,
                  color: AppColors.primary.withAlpha(26),
                  textColor: Colors.white,
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
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () {
                        context.go('/login');
                      },
                      child: const Text('Login'),
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

  Widget _buildGenderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.primary.withAlpha(128)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender,
          isExpanded: true,
          hint: const Text('Select Gender'),
          items: _genderOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _gender = newValue;
            });
          },
        ),
      ),
    );
  }
}
