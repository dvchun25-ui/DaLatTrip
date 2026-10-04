import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../auth/screens/login_screen.dart';
import '../../../auth/services/auth_service.dart';

/// Screen 12: Trang cá nhân
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Trang cá nhân',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Header Profile Card
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.mintBadge,
                          child: Icon(Icons.person, size: 45, color: AppColors.primary),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Nguyễn Thảo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.mintBadge,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Thành viên',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Menu Section
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildMenuItem(Icons.map_outlined, 'Lịch trình của tôi', () {}),
                  const Divider(height: 1, indent: 56, color: AppColors.divider),
                  _buildMenuItem(Icons.favorite_border, 'Địa điểm yêu thích', () {}),
                  const Divider(height: 1, indent: 56, color: AppColors.divider),
                  _buildMenuItem(Icons.rate_review_outlined, 'Đánh giá của tôi', () {}),
                  const Divider(height: 1, indent: 56, color: AppColors.divider),
                  _buildMenuItem(Icons.settings_outlined, 'Cài đặt', () {}),
                  const Divider(height: 1, indent: 56, color: AppColors.divider),
                  _buildMenuItem(Icons.help_outline, 'Trợ giúp', () {}),
                  const Divider(height: 1, indent: 56, color: AppColors.divider),
                  _buildMenuItem(
                    Icons.logout,
                    'Đăng xuất',
                    () async {
                      try {
                        await AuthService.instance.signOut();
                      } catch (_) {}
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    isDestructive: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? const Color(0xFFE53935) : AppColors.primary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: isDestructive ? const Color(0xFFE53935) : AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
      onTap: onTap,
    );
  }
}
