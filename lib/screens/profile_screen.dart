import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/navigations/app_layout.dart';
import '../utils/app_colors.dart';
import '../utils/responsive_helper.dart';
import '../widgets/inputs/rounded_input_field.dart';
import '../widgets/rounded_button.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile/profile_avatar.dart';
import '../widgets/profile/glass_container.dart';
import '../widgets/loading_skeleton.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../dao/database_helper.dart';
import '../models/profile_model.dart';
import '../utils/provider_snackbar_mixin.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with ProviderSnackbarMixin<ProfileProvider> {
  // Controllers for form fields
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  String _gender = 'MALE';
  String _activityLevel = 'MODERATELY_ACTIVE';
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  File? _image;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with default values
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();

    // Load profile data and setup snackbar callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupProviderSnackbar(context);
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
    clearProviderSnackbar(context);
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
      // Show source selection dialog
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Pilih Sumber Gambar'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Kamera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galeri'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image == null) return;

      // Validate file size (max 5MB)
      final File imageFile = File(image.path);
      final int fileSizeInBytes = await imageFile.length();
      final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      if (fileSizeInMB > 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ukuran file terlalu besar. Maksimal 5MB.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('Mengupload foto profil...'),
              ],
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 10),
          ),
        );
      }

      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      final success = await profileProvider.updateProfilePhoto(image);

      // Hide loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Foto profil berhasil diperbarui'),
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
              content: Text(
                'Gagal memperbarui foto profil: ${profileProvider.error ?? "Error tidak diketahui"}',
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(10),
              action: SnackBarAction(
                label: 'Coba Lagi',
                textColor: Colors.white,
                onPressed: () => _pickAndUploadImage(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking/uploading image: $e');
      if (mounted) {
        // Hide any existing snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: () => _pickAndUploadImage(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showDatabaseInfo(BuildContext context) async {
    try {
      final dbHelper = DatabaseHelper();
      final dbInfo = await dbHelper.getDatabaseInfo();

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📍 Database Info'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('📂 Path:', style: TextStyle(fontWeight: FontWeight.bold)),
                SelectableText(dbInfo['path'] ?? 'Unknown'),
                const SizedBox(height: 12),
                Text('📊 Details:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('• Exists: ${dbInfo['exists'] ? '✅' : '❌'}'),
                Text('• Version: ${dbInfo['version']}'),
                Text('• Size: ${dbInfo['size_mb']} MB'),
                Text('• Created: ${dbInfo['created_at'] ?? 'Unknown'}'),
                const SizedBox(height: 12),
                Text('📋 Tables:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...((dbInfo['tables'] as List)
                    .map((table) => Text('• $table'))),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                // Copy path to clipboard
                Clipboard.setData(ClipboardData(text: dbInfo['path']));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Path copied to clipboard!')),
                );
              },
              child: const Text('Copy Path'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    final isMobileLandscape = isMobile && isLandscape;

    return AppLayout(
      title: 'Profile',
      backgroundColor: const Color(0xFFF8F9FA),
      showBackButton: true,
      currentIndex: 2,
      actions: [],
      child: Consumer<ProfileProvider>(
        builder: (context, profileProvider, _) {
          // Show skeleton loading
          if (profileProvider.isLoading && profileProvider.profile == null) {
            return const ProfileSkeleton();
          }

          if (isMobileLandscape) {
            return _buildLandscapeLayout(profileProvider);
          } else {
            return _buildPortraitLayout(profileProvider);
          }
        },
      ),
    );
  }

  Widget _buildPortraitLayout(ProfileProvider profileProvider) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Profile header - ikut scroll
          Container(
            width: double.infinity,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildProfileHeader(profileProvider.profile),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Profile content - ikut dalam scroll yang sama
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildProfileContent(profileProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(ProfileProvider profileProvider) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Profile header
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildProfileHeader(profileProvider.profile,
                        isLandscape: true),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // Divider
            Container(
              width: 1,
              color: Colors.grey.shade200,
            ),
            // Right side - Profile form
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildProfileContent(profileProvider, isLandscape: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(ProfileProvider profileProvider,
      {bool isLandscape = false}) {
    // Error handling
    if (profileProvider.error != null &&
        profileProvider.profile == null &&
        !profileProvider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data profil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Silakan refresh halaman',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProfileData,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPersonalInfoSection(isLandscape: isLandscape),
        SizedBox(height: isLandscape ? 12 : 16),
        _buildLogoutSection(isLandscape: isLandscape),
        const SizedBox(height: 16),
        if (profileProvider.error != null)
          _buildErrorSection(profileProvider.error!),
        SizedBox(height: isLandscape ? 20 : 100), // Extra space for bottom nav
      ],
    );
  }

  Widget _buildProfileHeader(Profile? profile, {bool isLandscape = false}) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isMobileLandscape = isMobile && isLandscape;

    return Column(
      children: [
        GestureDetector(
          onDoubleTap: () => _showDatabaseInfo(context),
          child: ProfileAvatar(
            imagePath: profile?.photoUrl,
            size: isMobileLandscape ? 60 : 80,
            onTap: () {
              _pickAndUploadImage();
            },
          ),
        ),
        SizedBox(height: isMobileLandscape ? 6 : 8),
        Text(
          profile?.name ?? 'User',
          style: TextStyle(
            fontSize: isMobileLandscape ? 16 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: () {
            // Email display - no special functionality
          },
          child: Text(
            profile?.email ?? "user@email.com",
            style: TextStyle(
              fontSize: isMobileLandscape ? 12 : 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            if (!authProvider.isLoggedIn) {
              return Container(
                margin: EdgeInsets.only(top: isMobileLandscape ? 6 : 8),
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
                    fontSize: isMobileLandscape ? 10 : 12,
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
  }

  Widget _buildPersonalInfoSection({bool isLandscape = false}) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isMobileLandscape = isMobile && isLandscape;

    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Informasi Pribadi', isLandscape: isLandscape),
          SizedBox(height: isMobileLandscape ? 8 : 12),
          _buildFormField('Nama', _nameController, TextInputType.text,
              isLandscape: isLandscape),
          _buildFormField('Usia', _ageController, TextInputType.number,
              isLandscape: isLandscape),
          _buildGenderSelector(isLandscape: isLandscape),
          _buildFormField(
              'Tinggi (cm)', _heightController, TextInputType.number,
              isLandscape: isLandscape),
          _buildFormField('Berat (kg)', _weightController, TextInputType.number,
              isLandscape: isLandscape),
          _buildActivityLevelSelector(isLandscape: isLandscape),
          SizedBox(height: isMobileLandscape ? 8 : 12),
          Consumer<ProfileProvider>(
            builder: (context, provider, child) {
              return SizedBox(
                height: isMobileLandscape ? 40 : 50,
                child: RoundedButton(
                  text: provider.isLoading ? "Menyimpan..." : "Simpan Profil",
                  onPressed: provider.isLoading ? null : _saveProfile,
                  color: AppColors.primary,
                  isLoading: provider.isLoading,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection({bool isLandscape = false}) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAccountOption('Keluar', Icons.logout_outlined, () {
            _handleLogout();
          }, isLogout: true, isLandscape: isLandscape),
        ],
      ),
    );
  }

  Widget _buildErrorSection(String error) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Error'),
          const SizedBox(height: 12),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool isLandscape = false}) {
    return Text(
      title,
      style: TextStyle(
        fontSize: isLandscape ? 16 : 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller,
      TextInputType keyboardType,
      {bool isLandscape = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLandscape ? 13 : 13,
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

  Widget _buildGenderSelector({bool isLandscape = false}) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isMobileLandscape = isMobile && isLandscape;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jenis Kelamin',
          style: TextStyle(
            fontSize: isLandscape ? 13 : 13,
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

  Widget _buildActivityLevelSelector({bool isLandscape = false}) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isMobileLandscape = isMobile && isLandscape;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tingkat Aktivitas',
          style: TextStyle(
            fontSize: isLandscape ? 13 : 13,
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

  Widget _buildAccountOption(String title, IconData icon, VoidCallback onTap,
      {bool isLogout = false, bool isLandscape = false}) {
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
              color: isLogout ? Colors.red : AppColors.primary,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: isLandscape ? 14 : 14,
                fontWeight: FontWeight.w500,
                color: isLogout ? Colors.red : null,
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
