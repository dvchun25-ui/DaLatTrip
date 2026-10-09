import 'check_in_member.dart';

class CheckInRoom {
  final String id;
  final String name;
  final String ownerId;
  final List<CheckInMember> members;
  final DateTime createdAt;

  const CheckInRoom({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.members,
    required this.createdAt,
  });

  CheckInRoom copyWith({
    String? id,
    String? name,
    String? ownerId,
    List<CheckInMember>? members,
    DateTime? createdAt,
  }) {
    return CheckInRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'members': members.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CheckInRoom.fromJson(Map<String, dynamic> json) {
    return CheckInRoom(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'log',
      ownerId: json['ownerId']?.toString() ?? '',
      members: (json['members'] as List<dynamic>? ?? [])
          .map((m) => CheckInMember.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
