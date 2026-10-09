import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/social_login_button.dart';
import '../widgets/dalat_brand_widgets.dart';
import 'login_screen.dart';

import '../../features/navigation/main_navigation_screen.dart';

/// Màn hình Đăng nhập nhanh chuẩn 100% theo màn hình thứ 8 trong ảnh thiết kế
class QuickLoginScreen extends StatefulWidget {
  final AuthController? authController;

  const QuickLoginScreen({super.key, this.authController});

  @override
  State<QuickLoginScreen> createState() => _QuickLoginScreenState();
}

class _QuickLoginScreenState extends State<QuickLoginScreen> {
  late final AuthController _authController;
  String? _lastShownError;

  @override
  void initState() {
    super.initState();
    _authController = widget.authController ?? AuthController();
    _authController.addListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    final err = _authController.errorMessage;
    if (err != null && err.isNotEmpty && err != _lastShownError && mounted) {
      _lastShownError = err;
      _showSnackBar(err, isError: true);
    } else if (err == null) {
      _lastShownError = null;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _handleGoogle() async {
    ScaffoldMessenger.of(context).clearSnackBars();
    final success = await _authController.loginWithGoogle();
    if (success && mounted) {
      _showSnackBar('Đăng nhập Google thành công!');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleApple() async {
    ScaffoldMessenger.of(context).clearSnackBars();
    final success = await _authController.loginWithApple();
    if (success && mounted) {
      _showSnackBar('Đăng nhập Apple thành công!');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListenableBuilder(
        listenable: _authController,
        builder: (context, _) {
          return Column(
            children: [
              // Top header với cành thông sương mai và nút back
              const DalatHeaderBanner(height: 130),

              // Nội dung chính
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // Title
                      const Text(
                        'Đăng nhập nhanh',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Subtitle
                      const Text(
                        'Chọn phương thức bạn muốn sử dụng',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 1. Tiếp tục với Google
                      SocialLoginButton(
                        type: SocialType.google,
                        isFullWidth: true,
                        onPressed: _authController.isLoading
                            ? null
                            : _handleGoogle,
                      ),
                      const SizedBox(height: 16),

                      // 2. Tiếp tục với Apple
                      SocialLoginButton(
                        type: SocialType.apple,
                        isFullWidth: true,
                        onPressed: _authController.isLoading
                            ? null
                            : _handleApple,
                      ),
                      const SizedBox(height: 16),

                      // 3. Tiếp tục với Email
                      SocialLoginButton(
                        type: SocialType.email,
                        isFullWidth: true,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  LoginScreen(authController: _authController),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Biển chỉ dẫn gỗ "Đi Đà Lạt cùng Dalattrip ♡" và hoa cúc
              const DalatWoodenSignpost(),
            ],
          );
        },
      ),
    );
  }
}
