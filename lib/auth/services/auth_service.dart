import 'package:firebase_auth/firebase_auth.dart';

/// Service xử lý mọi nghiệp vụ xác thực liên kết trực tiếp với Firebase Auth
class AuthService {
  static final AuthService instance = AuthService();
  FirebaseAuth? _firebaseAuth;

  AuthService({
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth;

  FirebaseAuth get _auth => _firebaseAuth ??= FirebaseAuth.instance;

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
      throw Exception('Không thể gửi email đặt lại mật khẩu. Vui lòng thử lại.');
    }
  }

  /// Đăng nhập bằng Google thông qua Firebase Auth Provider
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      return await _auth.signInWithProvider(googleProvider);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw Exception('Đăng nhập với Google thất bại: ${e.toString()}');
    }
  }

  /// Đăng nhập bằng Apple thông qua Firebase Auth Provider
  Future<UserCredential> signInWithApple() async {
    try {
      final AppleAuthProvider appleProvider = AppleAuthProvider();
      return await _auth.signInWithProvider(appleProvider);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw Exception('Đăng nhập với Apple thất bại: ${e.toString()}');
    }
  }

  /// Đăng xuất tài khoản
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
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
