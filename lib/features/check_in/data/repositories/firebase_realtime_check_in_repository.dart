import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/firebase_database_config.dart';
import '../../domain/entities/check_in_entry.dart';
import '../../domain/entities/check_in_member.dart';
import '../../domain/entities/check_in_room.dart';
import '../../domain/repositories/check_in_repository.dart';
import 'local_check_in_repository.dart';

class FirebaseRealtimeCheckInRepository implements CheckInRepository {
  FirebaseRealtimeCheckInRepository._();

  static final FirebaseRealtimeCheckInRepository instance =
      FirebaseRealtimeCheckInRepository._();

  final LocalCheckInRepository _local = LocalCheckInRepository.instance;

  FirebaseDatabase get _database => FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: FirebaseDatabaseConfig.url,
      );

  DatabaseReference get _rooms => _database.ref('checkin_rooms');

  @override
  Future<CheckInRoom> createRoom({
    required String name,
    required String ownerId,
    required CheckInMember ownerMember,
  }) async {
    final room = CheckInRoom(
      id: 'room_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      ownerId: ownerId,
      members: [ownerMember],
      createdAt: DateTime.now(),
    );
    await _local.updateRoom(room);
    try {
      await _writeRoom(room);
    } catch (error) {
      debugPrint('Tạo room RTDB thất bại, giữ bản local: $error');
    }
    return room;
  }

  @override
  Future<List<CheckInRoom>> getRooms() async {
    try {
      final snapshot = await _rooms.get().timeout(const Duration(seconds: 10));
      final raw = _stringMap(snapshot.value);
      final rooms = raw.entries
          .map((entry) => _roomFromRemote(entry.key, entry.value))
          .whereType<CheckInRoom>()
          .toList();
      if (rooms.isNotEmpty) return rooms;
    } catch (error) {
      debugPrint('Đọc danh sách room RTDB thất bại: $error');
    }
    return _local.getRooms();
  }

  @override
  Future<CheckInRoom?> getRoomById(String id) async {
    try {
      final snapshot = await _rooms
          .child(id)
          .get()
          .timeout(const Duration(seconds: 10));
      final room = _roomFromRemote(id, snapshot.value);
      if (room != null) return room;
    } catch (error) {
      debugPrint('Đọc room RTDB thất bại: $error');
    }
    return _local.getRoomById(id);
  }

  @override
  Stream<CheckInRoom?> watchRoom(String id) async* {
    try {
      await for (final event in _rooms.child(id).onValue) {
        yield _roomFromRemote(id, event.snapshot.value) ??
            await _local.getRoomById(id);
      }
    } catch (error) {
      debugPrint('Listener room RTDB thất bại: $error');
      yield await _local.getRoomById(id);
    }
  }

  @override
  Future<void> updateRoom(CheckInRoom room) async {
    await _local.updateRoom(room);
    try {
      await _writeRoom(room);
    } catch (error) {
      debugPrint('Cập nhật room RTDB thất bại, giữ bản local: $error');
    }
  }

  @override
  Future<void> inviteMember(String roomId, CheckInMember member) async {
    await _local.inviteMember(roomId, member);
    try {
      await _rooms
          .child(roomId)
          .child('members')
          .child(member.userId)
          .set(_memberMetadata(member));
    } catch (error) {
      debugPrint('Mời thành viên qua RTDB thất bại: $error');
    }
  }

  @override
  Future<void> removeMember(String roomId, String userId) async {
    await _local.removeMember(roomId, userId);
    try {
      await _rooms.child(roomId).update({
        'members/$userId': null,
        'entries/$userId': null,
      });
    } catch (error) {
      debugPrint('Xóa thành viên khỏi RTDB thất bại: $error');
    }
  }

  @override
  Future<void> saveCheckInEntry({
    required String roomId,
    required String userId,
    required CheckInEntry entry,
  }) => replaceCheckInEntry(roomId: roomId, userId: userId, entry: entry);

  @override
  Future<void> replaceCheckInEntry({
    required String roomId,
    required String userId,
    required CheckInEntry entry,
  }) async {
    await _local.replaceCheckInEntry(
      roomId: roomId,
      userId: userId,
      entry: entry,
    );
    if (entry.mediaUrl == null || entry.mediaUrl!.isEmpty) return;
    try {
      await _rooms
          .child(roomId)
          .child('entries')
          .child(userId)
          .set(entry.toRemoteJson());
    } catch (error) {
      debugPrint('Ghi metadata check-in RTDB thất bại: $error');
    }
  }

  @override
  Future<void> deleteCheckInEntry({
    required String roomId,
    required String userId,
  }) async {
    await _local.deleteCheckInEntry(roomId: roomId, userId: userId);
    try {
      await _rooms.child(roomId).child('entries').child(userId).remove();
    } catch (error) {
      debugPrint('Xóa metadata check-in RTDB thất bại: $error');
    }
  }

  Future<void> _writeRoom(CheckInRoom room) async {
    final members = <String, Object?>{
      for (final member in room.members) member.userId: _memberMetadata(member),
    };
    await _rooms
        .child(room.id)
        .update({
          'name': room.name,
          'ownerId': room.ownerId,
          'createdAt': room.createdAt.toIso8601String(),
          'members': members,
        })
        .timeout(const Duration(seconds: 10));
  }

  Map<String, Object?> _memberMetadata(CheckInMember member) => {
    'userId': member.userId,
    'displayName': member.displayName,
    'username': member.username,
    'avatarUrl': member.avatarPath,
    'status': member.status.name,
  };

  CheckInRoom? _roomFromRemote(String id, Object? value) {
    final data = _stringMap(value);
    if (data.isEmpty) return null;
    final memberMap = _stringMap(data['members']);
    final entryMap = _stringMap(data['entries']);
    final members = memberMap.entries.map((item) {
      final memberData = _stringMap(item.value);
      final entryData = _stringMap(entryMap[item.key]);
      return CheckInMember(
        userId: memberData['userId']?.toString() ?? item.key,
        displayName: memberData['displayName']?.toString() ?? 'Người dùng',
        username: memberData['username']?.toString() ?? '',
        avatarPath: memberData['avatarUrl']?.toString(),
        status: CheckInMemberStatus.values.firstWhere(
          (status) => status.name == memberData['status'],
          orElse: () => CheckInMemberStatus.joined,
        ),
        checkInEntry: entryData.isEmpty
            ? null
            : CheckInEntry.fromJson(entryData),
      );
    }).toList();
    return CheckInRoom(
      id: id,
      name: data['name']?.toString() ?? 'log',
      ownerId: data['ownerId']?.toString() ?? '',
      members: members,
      createdAt:
          DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> _stringMap(Object? value) {
    if (value is! Map) return <String, dynamic>{};
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
}
