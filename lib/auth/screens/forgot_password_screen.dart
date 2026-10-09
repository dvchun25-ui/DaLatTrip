import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import '../widgets/dalat_brand_widgets.dart';

enum ForgotStep { enterEmail, resetPassword, success }

/// Màn hình Quên mật khẩu & Đặt lại mật khẩu chuẩn 100% theo bản thiết kế
class ForgotPasswordScreen extends StatefulWidget {
  final AuthController? authController;
  final ForgotStep initialStep;

  const ForgotPasswordScreen({
    super.key,
    this.authController,
    this.initialStep = ForgotStep.enterEmail,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();

  late final AuthController _authController;
  late ForgotStep _currentStep;

  String? _lastShownError;

  @override
  void initState() {
    super.initState();
    _authController = widget.authController ?? AuthController();
    _currentStep = widget.initialStep;
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

  Future<void> _handleSendResetEmail() async {
    ScaffoldMessenger.of(context).clearSnackBars();
    if (!_emailFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await _authController.forgotPassword(
      email: _emailController.text,
    );

    if (success && mounted) {
      setState(() {
        _currentStep = ForgotStep.success;
      });
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _currentStep = ForgotStep.success;
    });
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthStateChanged);
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final landscapeHeight = (size.height * 0.40).clamp(240.0, 360.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: _authController,
          builder: (context, _) {
            return Column(
              children: [
                // 1. Top Bar với nút Back
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      onPressed: () {
                        if (_currentStep == ForgotStep.resetPassword) {
                          setState(() => _currentStep = ForgotStep.enterEmail);
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                ),

                // 2. Nội dung Form được căn cao gọn gàng ở nửa trên
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildCurrentStepView(),
                      ),
                    ),
                  ),
                ),

                // 3. Phong cảnh đồi thông, nhà lồng kính & chữ thư pháp ở nửa dưới
                DalatBottomLandscape(
                  height: landscapeHeight,
                  quoteText: _currentStep == ForgotStep.success
                      ? 'Hẹn gặp lại bạn\nở Đà Lạt!'
                      : 'Da Lat\nvẫn luôn chờ bạn',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case ForgotStep.enterEmail:
        return _buildEnterEmailView();
      case ForgotStep.resetPassword:
        return _buildResetPasswordView();
      case ForgotStep.success:
        return _buildSuccessView();
    }
  }

  // 1. Bước 1: Quên mật khẩu? (Nhập email)
  Widget _buildEnterEmailView() {
    return Form(
      key: _emailFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Huy hiệu khóa
          const DalatBadgeIcon(icon: Icons.lock_outline_rounded, size: 68),
          const SizedBox(height: 16),

          // Title
          const Text(
            'Quên mật khẩu?',
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
            'Nhập email của bạn để nhận hướng dẫn\nđặt lại mật khẩu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),

          // Input Email
          AuthTextField(
            controller: _emailController,
            hintText: 'Email',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: AuthController.validateEmail,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSendResetEmail(),
            enabled: !_authController.isLoading,
          ),
          const SizedBox(height: 18),

          // Nút Gửi liên kết
          AuthButton(
            text: 'Gửi liên kết',
            isLoading: _authController.isLoading,
            onPressed: _handleSendResetEmail,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // 2. Bước 2: Đặt lại mật khẩu (Mật khẩu mới + xác nhận)
  Widget _buildResetPasswordView() {
    return Form(
      key: _resetFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DalatBadgeIcon(icon: Icons.lock_reset_rounded, size: 68),
          const SizedBox(height: 16),

          // Title
          const Text(
            'Đặt lại mật khẩu',
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
            'Tạo mật khẩu mới cho tài khoản\ncủa bạn',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Input: Mật khẩu mới
          AuthTextField(
            controller: _newPasswordController,
            hintText: 'Mật khẩu mới',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            validator: AuthController.validatePassword,
            enabled: !_authController.isLoading,
          ),
          const SizedBox(height: 12),

          // Input: Xác nhận mật khẩu mới
          AuthTextField(
            controller: _confirmNewPasswordController,
            hintText: 'Xác nhận mật khẩu mới',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            textInputAction: TextInputAction.done,
            validator: (val) => AuthController.validateConfirmPassword(
              _newPasswordController.text,
              val,
            ),
            onFieldSubmitted: (_) => _handleResetPassword(),
            enabled: !_authController.isLoading,
          ),
          const SizedBox(height: 18),

          // Nút Lưu mật khẩu
          AuthButton(
            text: 'Lưu mật khẩu',
            isLoading: _authController.isLoading,
            onPressed: _handleResetPassword,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // 3. Bước 3: Thành công (Huy hiệu tích xanh + Quay về đăng nhập)
  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Huy hiệu tích xanh
        const DalatBadgeIcon(
          icon: Icons.check_circle_outline_rounded,
          size: 68,
        ),
        const SizedBox(height: 16),

        // Title
        const Text(
          'Đặt lại mật khẩu\nthành công!',
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
          'Liên kết đặt lại mật khẩu đã được gửi đến email\ncủa bạn. Vui lòng kiểm tra hòm thư!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 22),

        // Nút Quay về đăng nhập
        AuthButton(
          text: 'Quay về đăng nhập',
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
