import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

/// Controller quản lý trạng thái xác thực và tương tác UI
class AuthController extends ChangeNotifier {
  AuthService? _authService;

  AuthController({AuthService? authService}) : _authService = authService;

  AuthService get authService => _authService ??= AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  User? _currentUser;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  User? get currentUser => _currentUser ?? authService.currentUser;
  bool get isAuthenticated => currentUser != null;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    _successMessage = null;
    notifyListeners();
  }

  void _setSuccess(String? message) {
    _successMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  /// Xóa các thông báo lỗi hoặc thành công trước đó
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Đăng nhập bằng Email & Password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    clearMessages();

    try {
      final credential = await authService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      _currentUser = credential.user;
      _setSuccess('Đăng nhập thành công!');
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  /// Đăng ký tài khoản mới
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (password != confirmPassword) {
      _setError('Mật khẩu xác nhận không trùng khớp.');
      return false;
    }

    _setLoading(true);
    clearMessages();

    try {
      final credential = await authService.registerWithEmailPassword(
        fullName: fullName,
        email: email,
        password: password,
      );
      _currentUser = credential.user;
      _setSuccess('Đăng ký tài khoản thành công!');
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  /// Gửi email đặt lại mật khẩu
  Future<bool> forgotPassword({required String email}) async {
    _setLoading(true);
    clearMessages();

    try {
      await authService.sendPasswordResetEmail(email: email);
      _setSuccess('Liên kết đặt lại mật khẩu đã được gửi tới email của bạn.');
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  /// Đăng nhập bằng Google
  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    clearMessages();

    try {
      final credential = await authService.signInWithGoogle();
      if (credential == null) {
        // User đã huỷ thao tác
        _setLoading(false);
        return false;
      }
      _currentUser = credential.user;
      _setSuccess('Đăng nhập Google thành công!');
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  /// Đăng nhập bằng Apple
  Future<bool> loginWithApple() async {
    _setLoading(true);
    clearMessages();

    try {
      final credential = await authService.signInWithApple();
      _currentUser = credential.user;
      _setSuccess('Đăng nhập Apple thành công!');
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  /// Đăng xuất
  Future<void> logout() async {
    _setLoading(true);
    try {
      await authService.signOut();
      _currentUser = null;
      clearMessages();
    } finally {
      _setLoading(false);
    }
  }

  // ================= VALIDATION FUNCTIONS =================

  /// Kiểm tra tính hợp lệ của Email
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không hợp lệ (ví dụ: travel@dalat.vn)';
    }
    return null;
  }

  /// Kiểm tra tính hợp lệ của Mật khẩu
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  /// Kiểm tra Họ và Tên
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên của bạn';
    }
    if (value.trim().length < 2) {
      return 'Họ tên quá ngắn';
    }
    return null;
  }

  /// Kiểm tra Mật khẩu xác nhận
  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (password != confirmPassword) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }
}
