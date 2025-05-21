import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/layouts/app_layout.dart';
import '../../../core/utils/app_colors.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/glass_container.dart';
import '../../../core/widgets/rounded_input_field.dart';
import '../../../core/widgets/rounded_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  String _gender = 'Pria';
  String? _selectedActivityLevel;
  File? _selectedImage;

  final List<String> _activityLevels = [
    'SEDENTARY',
    'LIGHTLY',
    'MODERATELY_ACTIVE',
    'VERY_ACTIVE',
    'EXTRA_ACTIVE'
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final profile = profileProvider.profile;
    
    _nameController = TextEditingController(text: profile?.name ?? '');
    _ageController = TextEditingController(text: profile?.age?.toString() ?? '');
    _heightController = TextEditingController(text: profile?.height?.toString() ?? '');
    _weightController = TextEditingController(text: profile?.weight?.toString() ?? '');
    
    // Set gender based on user data
    if (profile?.gender != null) {
      _gender = profile!.gender == 'MALE' ? 'Pria' : 'Wanita';
    }

    // Set activity level
    _selectedActivityLevel = profile?.activityLevel;

    // Load profile data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      profileProvider.getProfile();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      setState(() {
        _selectedImage = File(image.path);
      });

      // Upload image
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      await profileProvider.uploadProfileImage(_selectedImage!);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await _showLogoutConfirmation();
    if (confirmed && mounted) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      await profileProvider.logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  Future<bool> _showLogoutConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Konfirmasi Keluar'),
          content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Profile',
      backgroundColor: const Color(0xFFF8F9FA),
      showBottomNavBar: true,
      currentIndex: 2,
      child: Stack(
        children: [
          // Background gradients for glassmorphism effect
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(51),
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            left: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withAlpha(38),
              ),
            ),
          ),
          
          // Main content
          Consumer<ProfileProvider>(
            builder: (context, provider, child) {
              if (provider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(provider.error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => provider.getProfile(),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Profile header
                        _buildProfileHeader(provider),
                        
                        const SizedBox(height: 12),
                        
                        // Personal information section
                        GlassContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Informasi Pribadi'),
                              const SizedBox(height: 12),
                              
                              _buildFormField('Nama', _nameController, TextInputType.text),
                              _buildFormField('Usia', _ageController, TextInputType.number),
                              _buildGenderSelector(),
                              _buildFormField('Tinggi (cm)', _heightController, TextInputType.number),
                              _buildFormField('Berat (kg)', _weightController, TextInputType.number),
                              _buildActivityLevelSelector(),
                              
                              const SizedBox(height: 12),
                              RoundedButton(
                                text: "Simpan Profil",
                                onPressed: () => _saveProfile(provider),
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Health stats section
                        if (provider.profile != null)
                          GlassContainer(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Statistik Kesehatan'),
                                const SizedBox(height: 12),
                                _buildHealthStats(provider.profile!),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 16),
                        
                        // Account section
                        GlassContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Akun'),
                              const SizedBox(height: 12),
                              
                              _buildAccountOption(
                                'Ubah Password', 
                                Icons.lock_outline,
                                () {
                                  // Handle password change
                                }
                              ),
                              
                              _buildAccountOption(
                                'Notifikasi', 
                                Icons.notifications_none_outlined,
                                () {
                                  // Handle notifications
                                }
                              ),
                              
                              _buildAccountOption(
                                'Privasi', 
                                Icons.shield_outlined,
                                () {
                                  // Handle privacy settings
                                }
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Logout button
                        GlassContainer(
                          color: Colors.red.withAlpha(13),
                          borderColor: Colors.red.withAlpha(51),
                          child: InkWell(
                            onTap: provider.isLoading ? null : _handleLogout,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (provider.isLoading)
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.red.shade700,
                                        ),
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.logout_rounded,
                                      color: Colors.red.shade700,
                                      size: 20,
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    provider.isLoading ? "Keluar..." : "Keluar",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ProfileProvider provider) {
    final profile = provider.profile;
    
    return Column(
      children: [
        const SizedBox(height: 12),
        Stack(
          children: [
            ProfileAvatar(
              imageUrl: profile?.profileImage,
              size: 80,
              onTap: _pickImage,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          profile?.name ?? 'User',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          profile?.email ?? "user@email.com",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, TextInputType keyboardType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        RoundedInputField(
          controller: controller,
          hintText: 'Masukkan $label',
          keyboardType: keyboardType,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Mohon isi $label';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jenis Kelamin',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 134, 134, 134).withAlpha(38),
                blurRadius: 25,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _gender,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              items: ['Pria', 'Wanita'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _gender = newValue;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildActivityLevelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tingkat Aktivitas',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 134, 134, 134).withAlpha(38),
                blurRadius: 25,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedActivityLevel,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              items: _activityLevels.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value.replaceAll('_', ' ').toLowerCase(),
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedActivityLevel = newValue;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildHealthStats(ProfileModel profile) {
    return Column(
      children: [
        _buildStatRow('BMR', '${profile.bmr?.toStringAsFixed(0) ?? "N/A"} kcal'),
        _buildStatRow('TDEE', '${profile.tdee?.toStringAsFixed(0) ?? "N/A"} kcal'),
        if (profile.height != null && profile.weight != null)
          _buildStatRow(
            'BMI',
            '${(profile.weight! / ((profile.height! / 100) * (profile.height! / 100))).toStringAsFixed(1)}',
          ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountOption(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile(ProfileProvider provider) {
    if (_formKey.currentState!.validate()) {
      provider.updateProfile(
        name: _nameController.text,
        age: int.tryParse(_ageController.text),
        gender: _gender == 'Pria' ? 'MALE' : 'FEMALE',
        height: double.tryParse(_heightController.text),
        weight: double.tryParse(_weightController.text),
        activityLevel: _selectedActivityLevel,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profil berhasil disimpan'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }
} 