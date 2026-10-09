import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dalattrip/auth/services/auth_service.dart';
import 'package:dalattrip/auth/controllers/auth_controller.dart';
import 'package:dalattrip/auth/screens/splash_screen.dart';
import 'package:dalattrip/auth/screens/onboarding_screen.dart';
import 'package:dalattrip/auth/screens/login_screen.dart';
import 'package:dalattrip/auth/screens/register_screen.dart';
import 'package:dalattrip/auth/screens/forgot_password_screen.dart';
import 'package:dalattrip/auth/screens/quick_login_screen.dart';
import 'package:dalattrip/auth/widgets/auth_button.dart';

class TestAuthController extends AuthController {
  bool loginCalled = false;
  bool registerCalled = false;
  bool forgotPasswordCalled = false;

  @override
  Future<bool> login({required String email, required String password}) async {
    loginCalled = true;
    return true;
  }

  @override
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    registerCalled = true;
    return true;
  }

  @override
  Future<bool> forgotPassword({required String email}) async {
    forgotPasswordCalled = true;
    return true;
  }
}

void main() {
  group('1. Validation Logic', () {
    test('Validate Email', () {
      expect(AuthController.validateEmail(null), 'Vui lòng nhập email');
      expect(AuthController.validateEmail(''), 'Vui lòng nhập email');
      expect(AuthController.validateEmail('invalid-email'), isNotNull);
      expect(AuthController.validateEmail('test@dalattrip.vn'), isNull);
    });

    test('Validate Password', () {
      expect(AuthController.validatePassword(null), 'Vui lòng nhập mật khẩu');
      expect(
        AuthController.validatePassword('12345'),
        'Mật khẩu phải có ít nhất 6 ký tự',
      );
      expect(AuthController.validatePassword('123456'), isNull);
    });

    test('Validate Full Name', () {
      expect(
        AuthController.validateFullName(null),
        'Vui lòng nhập họ và tên của bạn',
      );
      expect(AuthController.validateFullName('A'), 'Họ tên quá ngắn');
      expect(AuthController.validateFullName('Nguyễn Văn A'), isNull);
    });

    test('Validate Confirm Password', () {
      expect(
        AuthController.validateConfirmPassword('123456', '654321'),
        'Mật khẩu xác nhận không khớp',
      );
      expect(
        AuthController.validateConfirmPassword('123456', '123456'),
        isNull,
      );
    });
  });

  group('2. OnboardingScreen', () {
    testWidgets('Hiển thị tiêu đề, 3 thẻ ảnh và nút Bắt đầu', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

      expect(find.textContaining('Lên kế hoạch'), findsOneWidget);
      expect(find.text('Bắt đầu'), findsOneWidget);

      await tester.tap(find.text('Bắt đầu'));
      await tester.pumpAndSettle();

      expect(find.textContaining('quán cà phê'), findsOneWidget);
    });
  });

  group('3. LoginScreen', () {
    testWidgets('Hiển thị thẻ trượt bo tròn và form đăng nhập', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockController = TestAuthController();

      await tester.pumpWidget(
        MaterialApp(home: LoginScreen(authController: mockController)),
      );

      expect(find.text('Chào mừng trở lại'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(find.text('Quên mật khẩu?'), findsOneWidget);
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.text('hoặc đăng nhập với'), findsOneWidget);
      expect(find.text('Đăng ký ngay'), findsOneWidget);

      await tester.tap(find.widgetWithText(AuthButton, 'Đăng nhập'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập email'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    });
  });

  group('4. RegisterScreen', () {
    testWidgets('Hiển thị 4 trường và header sương mờ', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockController = TestAuthController();

      await tester.pumpWidget(
        MaterialApp(home: RegisterScreen(authController: mockController)),
      );

      expect(find.text('Tạo tài khoản'), findsOneWidget);
      expect(find.text('Họ và tên'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(find.text('Xác nhận mật khẩu'), findsOneWidget);
      expect(find.text('Đăng ký'), findsOneWidget);

      await tester.tap(find.widgetWithText(AuthButton, 'Đăng ký'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập họ và tên của bạn'), findsOneWidget);
      expect(find.text('Vui lòng nhập email'), findsOneWidget);
    });
  });

  group('5. ForgotPasswordScreen', () {
    testWidgets('Quy trình Quên mật khẩu & Thành công', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockController = TestAuthController();

      await tester.pumpWidget(
        MaterialApp(home: ForgotPasswordScreen(authController: mockController)),
      );

      expect(find.text('Quên mật khẩu?'), findsOneWidget);
      expect(find.text('Gửi liên kết'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'test@dalattrip.vn');
      await tester.tap(find.widgetWithText(AuthButton, 'Gửi liên kết'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Đặt lại mật khẩu\nthành công!'),
        findsOneWidget,
      );
      expect(find.text('Quay về đăng nhập'), findsOneWidget);
    });
  });

  group('6. QuickLoginScreen', () {
    testWidgets('Hiển thị 3 nút đăng nhập nhanh và biển chỉ dẫn gỗ', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockController = TestAuthController();

      await tester.pumpWidget(
        MaterialApp(home: QuickLoginScreen(authController: mockController)),
      );

      expect(find.text('Đăng nhập nhanh'), findsOneWidget);
      expect(find.text('Chọn phương thức bạn muốn sử dụng'), findsOneWidget);
      expect(find.text('Tiếp tục với Google'), findsOneWidget);
      expect(find.text('Tiếp tục với Apple'), findsOneWidget);
      expect(find.text('Tiếp tục với Email'), findsOneWidget);
    });
  });

  group('7. Session Persistence & Auto-login', () {
    test('saveUserSession and clearUserSession work with SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final authService = AuthService();

      expect(await authService.hasSavedSession(), isFalse);

      await authService.saveUserSession(
        email: 'traveler@dalat.vn',
        displayName: 'Minh Thảo',
      );

      expect(await authService.hasSavedSession(), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AuthService.keyIsLoggedIn), isTrue);
      expect(prefs.getString(AuthService.keyUserEmail), 'traveler@dalat.vn');
      expect(prefs.getString(AuthService.keyUserName), 'Minh Thảo');

      await authService.clearUserSession();
      expect(await authService.hasSavedSession(), isFalse);
    });
  });

  group('8. SplashScreen Routing & Tap Tests', () {
    testWidgets('Lần đầu mở app -> điều hướng tới OnboardingScreen sau 1s', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({'has_seen_onboarding': false});

      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
      expect(find.text('Đi Đà Lạt'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();

      expect(find.textContaining('Lên kế hoạch'), findsOneWidget);
    });

    testWidgets('Mở app khi đã qua onboarding nhưng chưa đăng nhập -> điều hướng tới LoginScreen', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_onboarding': true,
        'is_logged_in': false,
      });

      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
      expect(find.text('Đi Đà Lạt'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();

      expect(find.text('Chào mừng trở lại'), findsOneWidget);
    });

    testWidgets('Người dùng chạm (tap) vào SplashScreen -> lập tức điều hướng không cần chờ hết 1s', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_onboarding': true,
        'is_logged_in': false,
      });

      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
      expect(find.text('Đi Đà Lạt'), findsOneWidget);

      // Chạm màn hình ngay lập tức
      await tester.tap(find.byType(SplashScreen));
      await tester.pumpAndSettle();

      expect(find.text('Chào mừng trở lại'), findsOneWidget);
    });
  });
}
