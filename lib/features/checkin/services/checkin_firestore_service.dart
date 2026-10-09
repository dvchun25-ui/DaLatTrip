import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CheckinPost {
  final String id;
  final String uid;
  final String userName;
  final String userAvatar;
  final String userId;
  final String placeName;
  final String placeAddress;
  final double? latitude;
  final double? longitude;
  final String content;
  final String imageUrl;
  final List<String> likes;
  final DateTime createdAt;

  const CheckinPost({
    required this.id,
    required this.uid,
    required this.userName,
    required this.userAvatar,
    required this.userId,
    required this.placeName,
    required this.placeAddress,
    this.latitude,
    this.longitude,
    required this.content,
    required this.imageUrl,
    this.likes = const [],
    required this.createdAt,
  });

  factory CheckinPost.fromFirestore(Map<String, dynamic> data, String docId) {
    return CheckinPost(
      id: docId,
      uid: data['uid']?.toString() ?? '',
      userName: data['userName']?.toString() ?? 'Du khách Đà Lạt',
      userAvatar: data['userAvatar']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      placeName: data['placeName']?.toString() ?? 'Đà Lạt',
      placeAddress: data['placeAddress']?.toString() ?? 'Đà Lạt, Lâm Đồng',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      content: data['content']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      likes: List<String>.from(data['likes'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'userName': userName,
      'userAvatar': userAvatar,
      'userId': userId,
      'placeName': placeName,
      'placeAddress': placeAddress,
      'latitude': latitude,
      'longitude': longitude,
      'content': content,
      'imageUrl': imageUrl,
      'likes': likes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class CheckinFirestoreService {
  static final CheckinFirestoreService instance = CheckinFirestoreService._internal();
  factory CheckinFirestoreService() => instance;
  CheckinFirestoreService._internal();

  FirebaseFirestore? _db;
  FirebaseFirestore get _firestore => _db ??= FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _checkinsCol =>
      _firestore.collection('checkins');

  /// Tạo bài Check-in mới
  Future<void> createCheckin(CheckinPost post) async {
    try {
      await _checkinsCol.add(post.toFirestore());
    } catch (e) {
      debugPrint('Lỗi tạo checkin: $e');
      rethrow;
    }
  }

  /// Stream danh sách bài đăng Check-in mới nhất thời gian thực
  Stream<List<CheckinPost>> streamCheckins() {
    return _checkinsCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((doc) => CheckinPost.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Thả tim / Thả thích bài viết
  Future<void> toggleLike(String checkinId, String uid) async {
    try {
      final docRef = _checkinsCol.doc(checkinId);
      final docSnap = await docRef.get();
      if (!docSnap.exists) return;

      final likes = List<String>.from(docSnap.data()?['likes'] ?? []);
      if (likes.contains(uid)) {
        await docRef.update({
          'likes': FieldValue.arrayRemove([uid]),
        });
      } else {
        await docRef.update({
          'likes': FieldValue.arrayUnion([uid]),
        });
      }
    } catch (e) {
      debugPrint('Lỗi toggleLike: $e');
    }
  }
}
