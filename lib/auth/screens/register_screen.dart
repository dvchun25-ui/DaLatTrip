import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_asset_images.dart';
import '../../features/navigation/main_navigation_screen.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import '../widgets/social_login_button.dart';
import '../widgets/dalat_brand_widgets.dart';

/// Màn hình Tạo tài khoản chuẩn 100% theo ảnh thiết kế
class RegisterScreen extends StatefulWidget {
  final AuthController? authController;

  const RegisterScreen({super.key, this.authController});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
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

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleRegister() async {
    ScaffoldMessenger.of(context).clearSnackBars();
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await _authController.register(
      fullName: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (success && mounted) {
      _showSnackBar('Tạo tài khoản thành công! Chào mừng bạn đến với Đà Lạt!');
      Future.delayed(const Duration(milliseconds: 600), _navigateToHome);
    }
  }

  Future<void> _handleGoogleLogin() async {
    ScaffoldMessenger.of(context).clearSnackBars();
    FocusScope.of(context).unfocus();
    final success = await _authController.loginWithGoogle();
    if (success && mounted) {
      _showSnackBar('Đăng nhập Google thành công!');
      Future.delayed(const Duration(milliseconds: 500), _navigateToHome);
    }
  }

  Future<void> _handleAppleLogin() async {
    ScaffoldMessenger.of(context).clearSnackBars();
    FocusScope.of(context).unfocus();
    final success = await _authController.loginWithApple();
    if (success && mounted) {
      _showSnackBar('Đăng nhập Apple thành công!');
      Future.delayed(const Duration(milliseconds: 500), _navigateToHome);
    }
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthStateChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFC8DEC9),
      body: Stack(
        children: [
          // 1. Ảnh phong cảnh đồi thông phủ toàn màn hình
          Positioned.fill(
            child: AppAssetImages.splashBg(
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          // Lớp sương mờ nghệ thuật
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.35),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Nút Back
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

          // 2. Thẻ trắng chứa form Đăng ký (Responsive)
          isWide
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 16,
                    ),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 460),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 24,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: _buildFormContent(context),
                    ),
                  ),
                )
              : Positioned.fill(
                  top: size.height * 0.18,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 16,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: _buildFormContent(context),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildFormContent(BuildContext context) {
    return ListenableBuilder(
      listenable: _authController,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 6),

                // Logo DALATTRIP
                const Center(
                  child: DalatLogo(showTagline: false, iconSize: 50),
                ),
                const SizedBox(height: 12),

                // Title
                const Text(
                  'Tạo tài khoản',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),

                // Subtitle
                const Text(
                  'Tham gia Dalattrip để bắt đầu\nkhám phá Đà Lạt theo cách của bạn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // 1. Họ và tên
                AuthTextField(
                  controller: _nameController,
                  hintText: 'Họ và tên',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: AuthController.validateFullName,
                  enabled: !_authController.isLoading,
                ),
                const SizedBox(height: 14),

                // 2. Email
                AuthTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: AuthController.validateEmail,
                  enabled: !_authController.isLoading,
                ),
                const SizedBox(height: 14),

                // 3. Mật khẩu
                AuthTextField(
                  controller: _passwordController,
                  hintText: 'Mật khẩu',
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: AuthController.validatePassword,
                  enabled: !_authController.isLoading,
                ),
                const SizedBox(height: 14),

                // 4. Xác nhận mật khẩu
                AuthTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Xác nhận mật khẩu',
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: (val) => AuthController.validateConfirmPassword(
                    _passwordController.text,
                    val,
                  ),
                  onFieldSubmitted: (_) => _handleRegister(),
                  enabled: !_authController.isLoading,
                ),
                const SizedBox(height: 22),

                // Nút Đăng ký
                AuthButton(
                  text: 'Đăng ký',
                  isLoading: _authController.isLoading,
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: 20),

                // Divider
                Row(
                  children: const [
                    Expanded(
                      child: Divider(color: AppColors.divider, thickness: 1),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'hoặc đăng ký với',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: AppColors.divider, thickness: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Social Buttons
                Row(
                  children: [
                    Expanded(
                      child: SocialLoginButton(
                        type: SocialType.google,
                        onPressed: _authController.isLoading
                            ? null
                            : _handleGoogleLogin,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: SocialLoginButton(
                        type: SocialType.apple,
                        onPressed: _authController.isLoading
                            ? null
                            : _handleAppleLogin,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Footer: Đã có tài khoản? Đăng nhập
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Đã có tài khoản? ',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Đăng nhập',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
