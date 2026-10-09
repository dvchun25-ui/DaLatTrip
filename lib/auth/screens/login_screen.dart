import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_asset_images.dart';
import '../../features/navigation/main_navigation_screen.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import '../widgets/social_login_button.dart';
import '../widgets/dalat_brand_widgets.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

/// Màn hình Đăng nhập chuẩn 100% theo thiết kế DaLatTrip
class LoginScreen extends StatefulWidget {
  final AuthController? authController;

  const LoginScreen({super.key, this.authController});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
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

  Future<void> _handleLogin() async {
    ScaffoldMessenger.of(context).clearSnackBars();
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await _authController.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (success && mounted) {
      _showSnackBar('Đăng nhập thành công! Chào mừng bạn đến với Đà Lạt!');
      Future.delayed(const Duration(milliseconds: 500), _navigateToHome);
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
    _emailController.dispose();
    _passwordController.dispose();
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
          // 1. Ảnh phong cảnh đồi thông sương mờ phủ toàn màn hình
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

          // 2. Thẻ trắng chứa form (Responsive chuẩn Mobile & Web)
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
                  top: size.height * 0.22,
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
                  child: DalatLogo(showTagline: false, iconSize: 52),
                ),
                const SizedBox(height: 14),

                // Title
                const Text(
                  'Chào mừng trở lại',
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
                  'Đăng nhập để tiếp tục hành trình khám phá\nĐà Lạt của bạn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Input: Email
                AuthTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: AuthController.validateEmail,
                  enabled: !_authController.isLoading,
                ),
                const SizedBox(height: 14),

                // Input: Mật khẩu
                AuthTextField(
                  controller: _passwordController,
                  hintText: 'Mật khẩu',
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: AuthController.validatePassword,
                  onFieldSubmitted: (_) => _handleLogin(),
                  enabled: !_authController.isLoading,
                ),
                const SizedBox(height: 10),

                // Quên mật khẩu
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _authController.isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                    child: const Text(
                      'Quên mật khẩu?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Nút Đăng nhập
                AuthButton(
                  text: 'Đăng nhập',
                  isLoading: _authController.isLoading,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: 20),

                // Hoặc đăng nhập với
                Row(
                  children: const [
                    Expanded(
                      child: Divider(color: AppColors.divider, thickness: 1),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'hoặc đăng nhập với',
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

                // Social Buttons (Google & Apple)
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

                // Footer: Chưa có tài khoản? Đăng ký ngay
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Chưa có tài khoản? ',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                RegisterScreen(authController: _authController),
                          ),
                        );
                      },
                      child: const Text(
                        'Đăng ký ngay',
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
