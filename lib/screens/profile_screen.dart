import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../widgets/navigations/app_layout.dart';
import '../utils/app_colors.dart';
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
  String _gender = 'Pria';

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    _nameController = TextEditingController(text: user?.name ?? 'Ulil');
    _ageController = TextEditingController(text: user?.age?.toString() ?? '21');
    _heightController =
        TextEditingController(text: user?.height?.toString() ?? '170');
    _weightController =
        TextEditingController(text: user?.weight?.toString() ?? '55');

    // Set gender based on user data
    if (user?.gender != null) {
      _gender = user!.gender == 'MALE' ? 'Pria' : 'Wanita';
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
                color: AppColors.primary.withValues(alpha: 0.2),
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
                color: AppColors.secondary.withValues(alpha: 0.15),
              ),
            ),
          ),

          // Main content
          SingleChildScrollView(
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
                        const SizedBox(height: 12),
                        RoundedButton(
                          text: "Simpan Profil",
                          onPressed: _saveProfile,
                          color: AppColors.primary,
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
                        _buildAccountOption('Ubah Password', Icons.lock_outline,
                            () {
                          // Handle password change
                        }),
                        _buildAccountOption(
                            'Notifikasi', Icons.notifications_none_outlined,
                            () {
                          // Handle notifications
                        }),
                        _buildAccountOption('Privasi', Icons.shield_outlined,
                            () {
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
                        color: Colors.red.withValues(alpha: 0.05),
                        borderColor: Colors.red.withValues(alpha: 0.2),
                        child: InkWell(
                          onTap: authProvider.isLoading ? null : _handleLogout,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (authProvider.isLoading)
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
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        return Column(
          children: [
            const SizedBox(height: 12),
            ProfileAvatar(
              imageUrl:
                  user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
              size: 80,
              onTap: () {
                // Handle tap on profile pic
              },
            ),
            const SizedBox(height: 8),
            Text(
              user?.name ?? 'User',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              user?.email ?? "user@email.com",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            if (!authProvider.isLoggedIn)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
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
              ),
          ],
        );
      },
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
                color: const Color.fromARGB(255, 134, 134, 134)
                    .withValues(alpha: 0.03),
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

  void _saveProfile() {
    // Show subtle animation or indicator
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
