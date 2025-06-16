import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/navigations/app_layout.dart';
import '../utils/app_colors.dart';
import '../utils/image_url_helper.dart';
import '../widgets/inputs/rounded_input_field.dart';
import '../widgets/rounded_button.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile/profile_avatar.dart';
import '../widgets/profile/glass_container.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Controllers for form fields
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  String _gender = 'MALE';
  String _activityLevel = 'MODERATELY_ACTIVE';
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    // Initialize controllers with default values
    _nameController = TextEditingController(text: '');
    _ageController = TextEditingController(text: '');
    _heightController = TextEditingController(text: '');
    _weightController = TextEditingController(text: '');

    // Load profile data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get profile provider
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);

      // Initialize profile if not already initialized
      if (!profileProvider.isInitialized) {
        await profileProvider.initializeProfile();
      }

      // Update controllers with profile data
      final profile = profileProvider.profile;
      if (profile != null) {
        setState(() {
          _nameController.text = profile.name;
          _ageController.text = profile.age.toString();
          _heightController.text = profile.height.toString();
          _weightController.text = profile.weight.toString();
          _gender = profile.gender;
          _activityLevel = profile.activityLevel;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: Colors.red,
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
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final confirmed = await _showLogoutConfirmation();
    if (confirmed) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
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
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                  child: const Text('Keluar'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _saveProfile() async {
    try {
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      final profile = profileProvider.profile;

      if (profile == null) {
        throw Exception('Profile not loaded');
      }

      // Validate input
      final age = int.tryParse(_ageController.text);
      final height = double.tryParse(_heightController.text);
      final weight = double.tryParse(_weightController.text);

      if (age == null || height == null || weight == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mohon isi semua data dengan benar'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Update profile with form values
      final updatedProfile = profile.copyWith(
        name: _nameController.text,
        age: age,
        gender: _gender,
        height: height,
        weight: weight,
        activityLevel: _activityLevel,
      );

      // Save profile
      final success = await profileProvider.updateProfile(updatedProfile);

      if (mounted) {
        if (success) {
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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan profil: ${profileProvider.error}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(10),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan profil: $e'),
            backgroundColor: Colors.red,
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

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 80,
      );
      
      if (image == null) return;
      
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final success = await profileProvider.updateProfilePhoto(image);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Foto profil berhasil diperbarui'),
              backgroundColor: AppColors.primary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memperbarui foto profil: ${profileProvider.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking/uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Profile',
      backgroundColor: const Color(0xFFF8F9FA),
      showBottomNavBar: true,
      showBackButton: false,
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
                color: AppColors.primary.withOpacity(0.2),
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
                color: AppColors.secondary.withOpacity(0.15),
              ),
            ),
          ),

          // Main content
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        // Profile header
                        _buildProfileHeader(),

                        const SizedBox(height: 12),

                        // Personal information section
                        GlassContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Informasi Pribadi'),
                              const SizedBox(height: 12),
                              _buildFormField(
                                  'Nama', _nameController, TextInputType.text),
                              _buildFormField(
                                  'Usia', _ageController, TextInputType.number),
                              _buildGenderSelector(),
                              _buildFormField('Tinggi (cm)', _heightController,
                                  TextInputType.number),
                              _buildFormField('Berat (kg)', _weightController,
                                  TextInputType.number),
                              _buildActivityLevelSelector(),
                              const SizedBox(height: 12),
                              Consumer<ProfileProvider>(
                                builder: (context, provider, child) {
                                  return RoundedButton(
                                    text: provider.isLoading
                                        ? "Menyimpan..."
                                        : "Simpan Profil",
                                    onPressed: provider.isLoading
                                        ? null
                                        : _saveProfile,
                                    color: AppColors.primary,
                                    isLoading: provider.isLoading,
                                  );
                                },
                              ),
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
                                  'Ubah Password', Icons.lock_outline, () {
                                // Handle password change
                              }),
                              _buildAccountOption('Notifikasi',
                                  Icons.notifications_none_outlined, () {
                                // Handle notifications
                              }),
                              _buildAccountOption(
                                  'Privasi', Icons.shield_outlined, () {
                                // Handle privacy settings
                              }),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Logout button
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            // Only show logout if user is logged in
                            if (!authProvider.isLoggedIn) {
                              return const SizedBox.shrink();
                            }

                            return GlassContainer(
                              color: Colors.red.withOpacity(0.05),
                              borderColor: Colors.red.withOpacity(0.2),
                              child: InkWell(
                                onTap: authProvider.isLoading
                                    ? null
                                    : _handleLogout,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (authProvider.isLoading)
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
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
                                        authProvider.isLoading
                                            ? "Keluar..."
                                            : "Keluar",
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
                            );
                          },
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final profile = profileProvider.profile;

        return Column(
          children: [
            const SizedBox(height: 12),
            ProfileAvatar(
              imagePath: profile?.photoUrl,
              size: 80,
              onTap: () {
                _pickAndUploadImage();
              },
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
            if (profile?.bmr != null && profile?.tdee != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    _buildMetricChip(
                      'BMR: ${profile?.bmr?.toStringAsFixed(0) ?? "0"} kcal',
                      Icons.local_fire_department_outlined,
                      AppColors.primary.withOpacity(0.8),
                    ),
                    _buildMetricChip(
                      'TDEE: ${profile?.tdee?.toStringAsFixed(0) ?? "0"} kcal',
                      Icons.fitness_center_outlined,
                      AppColors.secondary.withOpacity(0.8),
                    ),
                  ],
                ),
              ),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (!authProvider.isLoggedIn) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.warning.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'Mode Tamu',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
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

  Widget _buildFormField(String label, TextEditingController controller,
      TextInputType keyboardType) {
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
                color: Colors.grey.shade300.withOpacity(0.03),
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
              items: [
                DropdownMenuItem(
                  value: 'MALE',
                  child: const Text(
                    'Pria',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                DropdownMenuItem(
                  value: 'FEMALE',
                  child: const Text(
                    'Wanita',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
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
                color: Colors.grey.shade300.withOpacity(0.03),
                blurRadius: 25,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _activityLevel,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              items: [
                DropdownMenuItem(
                  value: 'SEDENTARY',
                  child: const Text(
                    'Tidak Aktif',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                DropdownMenuItem(
                  value: 'LIGHTLY',
                  child: const Text(
                    'Sedikit Aktif',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                DropdownMenuItem(
                  value: 'MODERATELY_ACTIVE',
                  child: const Text(
                    'Cukup Aktif',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                DropdownMenuItem(
                  value: 'VERY_ACTIVE',
                  child: const Text(
                    'Sangat Aktif',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                DropdownMenuItem(
                  value: 'EXTRA_ACTIVE',
                  child: const Text(
                    'Ekstra Aktif',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _activityLevel = newValue;
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
}