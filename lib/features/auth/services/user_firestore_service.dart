import 'package:firebase_auth/firebase_auth.dart';
import 'package:dalattrip/features/profile/domain/entities/user_profile.dart';
import 'package:dalattrip/features/profile/data/repositories/firestore_user_repository.dart';

export 'package:dalattrip/features/profile/domain/entities/user_profile.dart';

/// Legacy Service Wrapper tương thích với hệ thống hiện tại
class UserFirestoreService {
  static final UserFirestoreService instance = UserFirestoreService._internal();
  factory UserFirestoreService() => instance;
  UserFirestoreService._internal();

  final FirestoreUserRepository _repo = FirestoreUserRepository.instance;

  Future<UserProfile?> syncUserProfile(User user) =>
      _repo.syncUserProfile(user);

  Future<UserProfile?> getUserProfile(String uid) => _repo.getUserProfile(uid);

  Future<UserProfile?> getUserByUsername(String username) =>
      _repo.getUserByUsername(username);

  Stream<UserProfile?> streamUserProfile(String uid) =>
      _repo.streamUserProfile(uid);

  Future<List<UserProfile>> searchUsers(String query) =>
      _repo.searchUsers(query);

  Future<bool> isUsernameAvailable(String username) =>
      _repo.isUsernameAvailable(username);

  Future<void> updateUsername(String uid, String newUsername) =>
      _repo.updateUsername(uid, newUsername);

  Future<void> updateUserIdentity({
    required String uid,
    required String displayName,
    required String newUsername,
  }) => _repo.updateUserIdentity(
    uid: uid,
    displayName: displayName,
    newUsername: newUsername,
  );

  Future<void> updateAvatarUrl(String uid, String avatarUrl) =>
      _repo.updateAvatarUrl(uid, avatarUrl);

  Future<void> sendFriendRequest({
    required String currentUid,
    required String targetUid,
  }) => _repo.sendFriendRequest(currentUid: currentUid, targetUid: targetUid);

  Future<void> acceptFriendRequest({
    required String currentUid,
    required String targetUid,
  }) => _repo.acceptFriendRequest(currentUid: currentUid, targetUid: targetUid);

  Future<void> removeFriend({
    required String currentUid,
    required String targetUid,
  }) => _repo.removeFriend(currentUid: currentUid, targetUid: targetUid);
}
