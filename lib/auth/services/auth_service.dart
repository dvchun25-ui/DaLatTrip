import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service xử lý mọi nghiệp vụ xác thực liên kết trực tiếp với Firebase Auth
class AuthService {
  static final AuthService instance = AuthService();
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUserEmail = 'user_email';
  static const String keyUserName = 'user_display_name';

  FirebaseAuth? _firebaseAuth;
  GoogleSignIn? _googleSignIn;

  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth,
      _googleSignIn = googleSignIn;

  FirebaseAuth get _auth => _firebaseAuth ??= FirebaseAuth.instance;
  GoogleSignIn get _nativeGoogleSignIn =>
      _googleSignIn ??= GoogleSignIn(scopes: const ['email', 'profile']);

  /// Stream lắng nghe trạng thái đăng nhập thời gian thực
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Lấy user hiện tại đang đăng nhập
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Lưu trạng thái đăng nhập vào bộ nhớ cục bộ
  Future<void> saveUserSession({String? email, String? displayName}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyIsLoggedIn, true);
      if (email != null && email.isNotEmpty) {
        await prefs.setString(keyUserEmail, email);
      }
      if (displayName != null && displayName.isNotEmpty) {
        await prefs.setString(keyUserName, displayName);
      }
    } catch (_) {}
  }

  /// Xóa trạng thái đăng nhập khỏi bộ nhớ cục bộ
  Future<void> clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(keyIsLoggedIn);
      await prefs.remove(keyUserEmail);
      await prefs.remove(keyUserName);
    } catch (_) {}
  }

  /// Kiểm tra xem có phiên đăng nhập đã lưu trước đó không
  Future<bool> hasSavedSession() async {
    if (currentUser != null) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(keyIsLoggedIn) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Đăng nhập bằng Email và Mật khẩu
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await saveUserSession(
        email: credential.user?.email ?? email.trim(),
        displayName: credential.user?.displayName,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw Exception('Đã xảy ra lỗi không xác định. Vui lòng thử lại.');
    }
  }

  /// Đăng ký tài khoản mới bằng Email, Mật khẩu và Họ tên
  Future<UserCredential> registerWithEmailPassword({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Cập nhật tên hiển thị cho user
      if (credential.user != null && fullName.trim().isNotEmpty) {
        await credential.user!.updateDisplayName(fullName.trim());
        await credential.user!.reload();
      }

      await saveUserSession(
        email: email.trim(),
        displayName: fullName.trim(),
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw Exception('Đã xảy ra lỗi trong quá trình tạo tài khoản.');
    }
  }

  /// Gửi liên kết đặt lại mật khẩu qua Email
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw Exception(
        'Không thể gửi email đặt lại mật khẩu. Vui lòng thử lại.',
      );
    }
  }

  /// Android/iOS dùng account chooser native ngay trong ứng dụng.
  /// Web bắt buộc dùng popup OAuth do giới hạn bảo mật của trình duyệt.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        final credential = await _auth.signInWithPopup(provider);
        await _saveGoogleSession(credential);
        return credential;
      }

      if (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS) {
        throw Exception(
          'Đăng nhập Google native chỉ được hỗ trợ trên Android và iOS.',
        );
      }

      final GoogleSignInAccount? googleUser = await _nativeGoogleSignIn
          .signIn();
      if (googleUser == null) {
        // Người dùng hủy chọn tài khoản Google
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _saveGoogleSession(userCredential);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled') return null;
      if (e.code == 'network_error') {
        throw Exception(
          'Không thể kết nối Google. Vui lòng kiểm tra mạng và thử lại.',
        );
      }
      throw Exception(
        'Không thể mở đăng nhập Google trong ứng dụng. '
        'Hãy kiểm tra cấu hình SHA-1 của Firebase (${e.code}).',
      );
    } catch (e) {
      if (e is Exception &&
          e.toString().contains('Đăng nhập Google native')) {
        rethrow;
      }
      throw Exception('Đăng nhập với Google thất bại: ${e.toString()}');
    }
  }

  Future<void> _saveGoogleSession(UserCredential credential) async {
    if (credential.user == null) return;
    await saveUserSession(
      email: credential.user?.email,
      displayName: credential.user?.displayName,
    );
  }

  /// Đăng nhập bằng Apple thông qua Firebase Auth Provider
  Future<UserCredential> signInWithApple() async {
    try {
      final AppleAuthProvider appleProvider = AppleAuthProvider();
      final credential = await _auth.signInWithProvider(appleProvider);
      if (credential.user != null) {
        await saveUserSession(
          email: credential.user?.email,
          displayName: credential.user?.displayName,
        );
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw Exception('Đăng nhập với Apple thất bại: ${e.toString()}');
    }
  }

  /// Đăng xuất tài khoản
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        try {
          await _googleSignIn?.signOut();
        } catch (_) {
          // Firebase sign-out must still continue if Google Play Services fails.
        }
      }
      await _auth.signOut();
      await clearUserSession();
    } catch (e) {
      await clearUserSession();
      throw Exception('Đăng xuất thất bại. Vui lòng thử lại.');
    }
  }

  /// Xử lý mã lỗi Firebase thành thông điệp tiếng Việt thân thiện
  String _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Tài khoản email này chưa được đăng ký trong hệ thống.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại.';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng cho một tài khoản khác.';
      case 'invalid-email':
        return 'Địa chỉ email không đúng định dạng.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng đặt mật khẩu tối thiểu 6 ký tự.';
      case 'user-disabled':
        return 'Tài khoản này hiện đã bị tạm khóa.';
      case 'too-many-requests':
        return 'Bạn đã thử quá nhiều lần. Vui lòng chờ ít phút và thử lại.';
      case 'network-request-failed':
        return 'Không có kết nối mạng. Vui lòng kiểm tra lại đường truyền Internet.';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập này chưa được kích hoạt trên hệ thống.';
      default:
        return e.message ?? 'Đã có lỗi xảy ra. Vui lòng thử lại sau.';
    }
  }
}
