import 'package:cloud_firestore/cloud_firestore.dart';

/// UserProfile đại diện cho thông tin tài khoản người dùng trong DALATTRIP
class UserProfile {
  final String uid;
  final String email;
  final String username;
  final String displayName;
  final String? avatarPath;
  final String? bio;
  final List<String> friends;
  final List<String> sentRequests;
  final List<String> receivedRequests;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.username,
    required this.displayName,
    this.avatarPath,
    this.bio = 'Yêu du lịch Đà Lạt 🌲',
    this.friends = const [],
    this.sentRequests = const [],
    this.receivedRequests = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final emailVal = data['email']?.toString() ?? '';
    final rawUsername = data['username']?.toString() ?? data['userId']?.toString() ?? '';
    final usernameVal = rawUsername.isNotEmpty
        ? rawUsername
        : (emailVal.contains('@') ? emailVal.split('@').first : 'user_${docId.substring(0, 6)}');

    return UserProfile(
      uid: docId,
      email: emailVal,
      username: usernameVal,
      displayName: data['displayName']?.toString() ?? 'Người dùng DaLatTrip',
      avatarPath: data['avatarPath']?.toString() ?? data['photoUrl']?.toString(),
      bio: data['bio']?.toString() ?? 'Yêu du lịch Đà Lạt 🌲',
      friends: List<String>.from(data['friends'] ?? []),
      sentRequests: List<String>.from(data['sentRequests'] ?? []),
      receivedRequests: List<String>.from(data['receivedRequests'] ?? []),
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'userId': username, // legacy compatibility
      'displayName': displayName,
      'avatarPath': avatarPath,
      'photoUrl': avatarPath,
      'bio': bio,
      'friends': friends,
      'sentRequests': sentRequests,
      'receivedRequests': receivedRequests,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserProfile copyWith({
    String? email,
    String? username,
    String? displayName,
    String? avatarPath,
    String? bio,
    List<String>? friends,
    List<String>? sentRequests,
    List<String>? receivedRequests,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarPath: avatarPath ?? this.avatarPath,
      bio: bio ?? this.bio,
      friends: friends ?? this.friends,
      sentRequests: sentRequests ?? this.sentRequests,
      receivedRequests: receivedRequests ?? this.receivedRequests,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
