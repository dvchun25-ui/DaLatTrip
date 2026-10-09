import 'check_in_entry.dart';

enum CheckInMemberStatus { invited, joined, owner }

class CheckInMember {
  final String userId;
  final String displayName;
  final String username;
  final String? avatarPath;
  final CheckInMemberStatus status;
  final CheckInEntry? checkInEntry;

  const CheckInMember({
    required this.userId,
    required this.displayName,
    required this.username,
    this.avatarPath,
    this.status = CheckInMemberStatus.joined,
    this.checkInEntry,
  });

  CheckInMember copyWith({
    String? userId,
    String? displayName,
    String? username,
    String? avatarPath,
    CheckInMemberStatus? status,
    CheckInEntry? checkInEntry,
  }) {
    return CheckInMember(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      avatarPath: avatarPath ?? this.avatarPath,
      status: status ?? this.status,
      checkInEntry: checkInEntry ?? this.checkInEntry,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'username': username,
      'avatarPath': avatarPath,
      'status': status.name,
      'checkInEntry': checkInEntry?.toJson(),
    };
  }

  factory CheckInMember.fromJson(Map<String, dynamic> json) {
    return CheckInMember(
      userId: json['userId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'Người dùng',
      username: json['username']?.toString() ?? '',
      avatarPath: json['avatarPath']?.toString(),
      status: CheckInMemberStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CheckInMemberStatus.joined,
      ),
      checkInEntry: json['checkInEntry'] != null
          ? CheckInEntry.fromJson(Map<String, dynamic>.from(json['checkInEntry']))
          : null,
    );
  }
}
