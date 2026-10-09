import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:dalattrip/core/utils/search_text_utils.dart';
import 'package:dalattrip/core/utils/username_utils.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';

class FirestoreUserRepository implements UserRepository {
  static final FirestoreUserRepository instance =
      FirestoreUserRepository._internal();
  factory FirestoreUserRepository() => instance;
  FirestoreUserRepository._internal();

  FirebaseFirestore? _db;
  FirebaseFirestore get _firestore => _db ??= FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _usernamesCol =>
      _firestore.collection('usernames');

  @override
  Future<UserProfile?> getUserByUid(String uid) async {
    try {
      final doc = await _usersCol.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromFirestore(doc.data()!, doc.id);
      }
    } catch (e) {
      debugPrint('Lỗi getUserByUid: $e');
    }
    return null;
  }

  @override
  Future<UserProfile?> getUserProfile(String uid) => getUserByUid(uid);

  @override
  Future<UserProfile?> getUserByUsername(String username) async {
    final cleanUsername = UsernameUtils.normalizeUsername(username);
    if (cleanUsername.isEmpty) return null;

    try {
      final lockDoc = await _usernamesCol.doc(cleanUsername).get();
      if (lockDoc.exists && lockDoc.data() != null) {
        final uid = lockDoc.data()!['uid']?.toString();
        if (uid != null && uid.isNotEmpty) {
          return getUserByUid(uid);
        }
      }

      // Fallback query if username lock missing
      final snap = await _usersCol
          .where('username', isEqualTo: cleanUsername)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        return UserProfile.fromFirestore(
          snap.docs.first.data(),
          snap.docs.first.id,
        );
      }
    } catch (e) {
      debugPrint('Lỗi getUserByUsername: $e');
    }
    return null;
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final cleanUsername = UsernameUtils.normalizeUsername(username);
    final validationError = UsernameUtils.validateUsername(cleanUsername);
    if (validationError != null) return false;

    try {
      final doc = await _usernamesCol.doc(cleanUsername).get();
      return !doc.exists;
    } catch (e) {
      debugPrint('Lỗi isUsernameAvailable: $e');
      return false;
    }
  }

  @override
  Future<UserProfile?> syncUserProfile(User user) async {
    try {
      final docRef = _usersCol.doc(user.uid);
      final docSnap = await docRef.get();

      if (docSnap.exists && docSnap.data() != null) {
        final existing = UserProfile.fromFirestore(docSnap.data()!, user.uid);

        // Ensure usernames lock document exists for legacy users
        final userLock = await _usernamesCol.doc(existing.username).get();
        if (!userLock.exists) {
          await _usernamesCol.doc(existing.username).set({
            'uid': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        final updatedData = <String, dynamic>{
          if (user.displayName != null &&
              user.displayName!.isNotEmpty &&
              existing.displayName == 'Người dùng DaLatTrip')
            'displayName': user.displayName,
          'displayNameNormalized': SearchTextUtils.normalize(
            (user.displayName != null && user.displayName!.isNotEmpty)
                ? user.displayName!
                : existing.displayName,
          ),
          if (user.photoURL != null &&
              user.photoURL!.isNotEmpty &&
              (existing.avatarUrl == null || existing.avatarUrl!.isEmpty))
            'avatarUrl': user.photoURL,
          'email': user.email ?? existing.email,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (updatedData.isNotEmpty) {
          await docRef.update(updatedData);
        }
        return getUserByUid(user.uid);
      } else {
        // Create new user profile with unique username generated from email
        final email = user.email ?? '';
        final baseUsername = UsernameUtils.generateDefaultUsername(email);

        String candidateUsername = baseUsername;
        int counter = 1;

        while (!(await isUsernameAvailable(candidateUsername))) {
          candidateUsername = '${baseUsername}_$counter';
          counter++;
        }

        final now = DateTime.now();
        final newProfile = UserProfile(
          uid: user.uid,
          email: email,
          username: candidateUsername,
          displayName:
              (user.displayName != null && user.displayName!.isNotEmpty)
              ? user.displayName!
              : (email.contains('@')
                    ? email.split('@').first
                    : 'Khách du lịch'),
          avatarUrl: user.photoURL,
          avatarPath: user.photoURL ?? '',
          createdAt: now,
          updatedAt: now,
        );

        final batch = _firestore.batch();
        batch.set(docRef, {
          ...newProfile.toFirestore(),
          'displayNameNormalized': SearchTextUtils.normalize(
            newProfile.displayName,
          ),
        });
        batch.set(_usernamesCol.doc(candidateUsername), {
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();
        return newProfile;
      }
    } catch (e) {
      debugPrint('Lỗi syncUserProfile: $e');
      return null;
    }
  }

  Future<void> updateAvatarUrl(String uid, String avatarUrl) async {
    if (!avatarUrl.startsWith('https://')) {
      throw ArgumentError.value(
        avatarUrl,
        'avatarUrl',
        'Avatar URL phải dùng HTTPS.',
      );
    }
    await _usersCol.doc(uid).set({
      'avatarUrl': avatarUrl,
      'photoUrl': avatarUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateUsername(String uid, String newUsername) async {
    final profile = await getUserByUid(uid);
    if (profile == null) {
      throw Exception('Không tìm thấy tài khoản người dùng.');
    }
    await updateUserIdentity(
      uid: uid,
      displayName: profile.displayName,
      newUsername: newUsername,
    );
  }

  Future<void> updateUserIdentity({
    required String uid,
    required String displayName,
    required String newUsername,
  }) async {
    final cleanNewUsername = UsernameUtils.normalizeUsername(newUsername);
    final validationError = UsernameUtils.validateUsername(cleanNewUsername);
    final cleanDisplayName = displayName.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (validationError != null) {
      throw Exception(validationError);
    }
    if (cleanDisplayName.length < 2 || cleanDisplayName.length > 40) {
      throw Exception('Biệt danh phải có từ 2 đến 40 ký tự.');
    }

    return _firestore.runTransaction((transaction) async {
      final userDocRef = _usersCol.doc(uid);
      final userSnap = await transaction.get(userDocRef);

      if (!userSnap.exists || userSnap.data() == null) {
        throw Exception('Không tìm thấy tài khoản người dùng.');
      }

      final currentData = userSnap.data()!;
      final oldUsername =
          currentData['username']?.toString() ??
          currentData['userId']?.toString() ??
          '';

      if (oldUsername != cleanNewUsername) {
        final newLockRef = _usernamesCol.doc(cleanNewUsername);
        final newLockSnap = await transaction.get(newLockRef);

        if (newLockSnap.exists) {
          final existingUid = newLockSnap.data()?['uid'];
          if (existingUid != uid) {
            throw Exception(
              'Tên người dùng đã được sử dụng. Vui lòng chọn tên khác.',
            );
          }
        }

        if (oldUsername.isNotEmpty) {
          transaction.delete(_usernamesCol.doc(oldUsername));
        }

        transaction.set(newLockRef, {
          'uid': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.update(userDocRef, {
        'username': cleanNewUsername,
        'userId': cleanNewUsername,
        'displayName': cleanDisplayName,
        'displayNameNormalized': SearchTextUtils.normalize(cleanDisplayName),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<List<UserProfile>> searchUsers(String keyword) async {
    var usernameKeyword = keyword.trim().toLowerCase();
    if (usernameKeyword.startsWith('@')) {
      usernameKeyword = usernameKeyword.substring(1);
    }
    usernameKeyword = UsernameUtils.normalizeUsername(usernameKeyword);
    final nicknameKeyword = SearchTextUtils.normalize(
      keyword.replaceFirst('@', ''),
    );

    if (usernameKeyword.isEmpty && nicknameKeyword.isEmpty) return [];

    try {
      final resultsMap = <String, UserProfile>{};

      if (usernameKeyword.isNotEmpty) {
        final usernameSnap = await _usersCol
            .where('username', isGreaterThanOrEqualTo: usernameKeyword)
            .where('username', isLessThanOrEqualTo: '$usernameKeyword\uf8ff')
            .limit(20)
            .get();

        for (final doc in usernameSnap.docs) {
          final user = UserProfile.fromFirestore(doc.data(), doc.id);
          resultsMap[user.uid] = user;
        }
      }

      if (nicknameKeyword.isNotEmpty) {
        final nicknameSnap = await _usersCol
            .where(
              'displayNameNormalized',
              isGreaterThanOrEqualTo: nicknameKeyword,
            )
            .where(
              'displayNameNormalized',
              isLessThanOrEqualTo: '$nicknameKeyword\uf8ff',
            )
            .limit(20)
            .get();
        for (final doc in nicknameSnap.docs) {
          final user = UserProfile.fromFirestore(doc.data(), doc.id);
          resultsMap[user.uid] = user;
        }
      }

      // Hỗ trợ hồ sơ cũ chưa có displayNameNormalized và tìm chứa từ khóa.
      final allDocs = await _usersCol.limit(100).get();
      for (final doc in allDocs.docs) {
        final user = UserProfile.fromFirestore(doc.data(), doc.id);
        final matchesName =
            nicknameKeyword.isNotEmpty &&
            SearchTextUtils.normalize(
              user.displayName,
            ).contains(nicknameKeyword);
        final matchesUsername =
            usernameKeyword.isNotEmpty &&
            user.username.toLowerCase().contains(usernameKeyword);
        if (matchesName || matchesUsername) {
          resultsMap[user.uid] = user;
        }
      }

      return resultsMap.values.toList();
    } catch (e) {
      debugPrint('Lỗi searchUsers: $e');
      return [];
    }
  }

  @override
  Stream<UserProfile?> streamUserProfile(String uid) {
    return _usersCol.doc(uid).snapshots().map((snap) {
      if (snap.exists && snap.data() != null) {
        return UserProfile.fromFirestore(snap.data()!, snap.id);
      }
      return null;
    });
  }

  @override
  Future<void> sendFriendRequest({
    required String currentUid,
    required String targetUid,
  }) async {
    if (currentUid == targetUid) return;
    final batch = _firestore.batch();
    final currentRef = _usersCol.doc(currentUid);
    final targetRef = _usersCol.doc(targetUid);

    batch.update(currentRef, {
      'sentRequests': FieldValue.arrayUnion([targetUid]),
    });
    batch.update(targetRef, {
      'receivedRequests': FieldValue.arrayUnion([currentUid]),
    });

    await batch.commit();
  }

  @override
  Future<void> acceptFriendRequest({
    required String currentUid,
    required String targetUid,
  }) async {
    final batch = _firestore.batch();
    final currentRef = _usersCol.doc(currentUid);
    final targetRef = _usersCol.doc(targetUid);

    batch.update(currentRef, {
      'friends': FieldValue.arrayUnion([targetUid]),
      'receivedRequests': FieldValue.arrayRemove([targetUid]),
    });
    batch.update(targetRef, {
      'friends': FieldValue.arrayUnion([currentUid]),
      'sentRequests': FieldValue.arrayRemove([currentUid]),
    });

    await batch.commit();
  }

  @override
  Future<void> removeFriend({
    required String currentUid,
    required String targetUid,
  }) async {
    final batch = _firestore.batch();
    final currentRef = _usersCol.doc(currentUid);
    final targetRef = _usersCol.doc(targetUid);

    batch.update(currentRef, {
      'friends': FieldValue.arrayRemove([targetUid]),
    });
    batch.update(targetRef, {
      'friends': FieldValue.arrayRemove([currentUid]),
    });

    await batch.commit();
  }
}
