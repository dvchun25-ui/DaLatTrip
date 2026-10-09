import 'package:firebase_auth/firebase_auth.dart';
import '../entities/user_profile.dart';

abstract class UserRepository {
  /// Lấy hồ sơ người dùng theo UID
  Future<UserProfile?> getUserByUid(String uid);

  /// Lấy hồ sơ người dùng theo UID (bí danh)
  Future<UserProfile?> getUserProfile(String uid);

  /// Lấy hồ sơ người dùng theo username
  Future<UserProfile?> getUserByUsername(String username);

  /// Tìm kiếm người dùng theo keyword (chủ yếu theo @username và displayName, KHÔNG theo email công khai)
  Future<List<UserProfile>> searchUsers(String keyword);

  /// Kiểm tra username có khả dụng (chưa ai sử dụng) không
  Future<bool> isUsernameAvailable(String username);

  /// Cập nhật username bằng transaction/batch (xóa lock cũ, tạo lock mới, update user profile)
  Future<void> updateUsername(String uid, String newUsername);

  /// Đồng bộ/khởi tạo profile khi Đăng nhập/Đăng ký với email/password hoặc Google
  Future<UserProfile?> syncUserProfile(User user);

  /// Stream lắng nghe thông tin profile theo UID
  Stream<UserProfile?> streamUserProfile(String uid);

  /// Gửi lời mời kết bạn (dùng UID)
  Future<void> sendFriendRequest({required String currentUid, required String targetUid});

  /// Chấp nhận lời mời kết bạn (dùng UID)
  Future<void> acceptFriendRequest({required String currentUid, required String targetUid});

  /// Hủy kết bạn (dùng UID)
  Future<void> removeFriend({required String currentUid, required String targetUid});
}
