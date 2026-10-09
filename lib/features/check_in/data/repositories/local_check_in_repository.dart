import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/check_in_entry.dart';
import '../../domain/entities/check_in_member.dart';
import '../../domain/entities/check_in_room.dart';
import '../../domain/repositories/check_in_repository.dart';

class LocalCheckInRepository implements CheckInRepository {
  static final LocalCheckInRepository instance = LocalCheckInRepository._internal();
  factory LocalCheckInRepository() => instance;
  LocalCheckInRepository._internal();

  List<CheckInRoom> _memoryRooms = [];
  bool _isInitialized = false;

  Future<File> _getStorageFile() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docsDir.path}/dalattrip');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File('${dir.path}/check_in_rooms.json');
  }

  Future<void> _init() async {
    if (_isInitialized) return;
    try {
      final file = await _getStorageFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final decoded = jsonDecode(content) as List<dynamic>;
          _memoryRooms = decoded
              .map((item) => CheckInRoom.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Lỗi đọc local checkin rooms: $e');
    }

    if (_memoryRooms.isEmpty) {
      // Khởi tạo phòng mẫu mặc định matching Screenshot 1 & 4
      _memoryRooms = [_createDefaultRoom()];
      await _saveToDisk();
    }
    _isInitialized = true;
  }

  CheckInRoom _createDefaultRoom() {
    return CheckInRoom(
      id: 'room_log_001',
      name: 'log',
      ownerId: 'chung_user',
      members: const [
        CheckInMember(
          userId: 'chung_user',
          displayName: 'Chung',
          username: 'chung_dalat',
          status: CheckInMemberStatus.owner,
        ),
      ],
      createdAt: DateTime.now(),
    );
  }

  Future<void> _saveToDisk() async {
    try {
      final file = await _getStorageFile();
      final jsonList = _memoryRooms.map((r) => r.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Lỗi ghi local checkin rooms: $e');
    }
  }

  @override
  Future<CheckInRoom> createRoom({
    required String name,
    required String ownerId,
    required CheckInMember ownerMember,
  }) async {
    await _init();
    final newRoom = CheckInRoom(
      id: 'room_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      ownerId: ownerId,
      members: [ownerMember],
      createdAt: DateTime.now(),
    );
    _memoryRooms.add(newRoom);
    await _saveToDisk();
    return newRoom;
  }

  @override
  Future<List<CheckInRoom>> getRooms() async {
    await _init();
    return List.unmodifiable(_memoryRooms);
  }

  @override
  Future<CheckInRoom?> getRoomById(String id) async {
    await _init();
    for (final room in _memoryRooms) {
      if (room.id == id) return room;
    }
    return _memoryRooms.firstOrNull;
  }

  @override
  Future<void> updateRoom(CheckInRoom room) async {
    await _init();
    final index = _memoryRooms.indexWhere((r) => r.id == room.id);
    if (index != -1) {
      _memoryRooms[index] = room;
    } else {
      _memoryRooms.add(room);
    }
    await _saveToDisk();
  }

  @override
  Future<void> inviteMember(String roomId, CheckInMember member) async {
    await _init();
    final room = await getRoomById(roomId);
    if (room == null) return;
    if (room.members.length >= 4) {
      throw Exception('Phòng đã đủ 4 thành viên');
    }

    final updatedMembers = List<CheckInMember>.from(room.members);
    final existingIdx = updatedMembers.indexWhere((m) => m.userId == member.userId);
    if (existingIdx != -1) {
      updatedMembers[existingIdx] = member;
    } else {
      updatedMembers.add(member);
    }

    await updateRoom(room.copyWith(members: updatedMembers));
  }

  @override
  Future<void> removeMember(String roomId, String userId) async {
    await _init();
    final room = await getRoomById(roomId);
    if (room == null) return;

    final updatedMembers = room.members.where((m) => m.userId != userId).toList();
    await updateRoom(room.copyWith(members: updatedMembers));
  }

  @override
  Future<void> saveCheckInEntry({
    required String roomId,
    required String userId,
    required CheckInEntry entry,
  }) async {
    await replaceCheckInEntry(roomId: roomId, userId: userId, entry: entry);
  }

  @override
  Future<void> replaceCheckInEntry({
    required String roomId,
    required String userId,
    required CheckInEntry entry,
  }) async {
    await _init();
    final room = await getRoomById(roomId);
    if (room == null) return;

    final updatedMembers = room.members.map((m) {
      if (m.userId == userId) {
        return m.copyWith(checkInEntry: entry);
      }
      return m;
    }).toList();

    await updateRoom(room.copyWith(members: updatedMembers));
  }

  @override
  Future<void> deleteCheckInEntry({
    required String roomId,
    required String userId,
  }) async {
    await _init();
    final room = await getRoomById(roomId);
    if (room == null) return;

    final updatedMembers = room.members.map((m) {
      if (m.userId == userId) {
        return CheckInMember(
          userId: m.userId,
          displayName: m.displayName,
          username: m.username,
          avatarPath: m.avatarPath,
          status: m.status,
          checkInEntry: null,
        );
      }
      return m;
    }).toList();

    await updateRoom(room.copyWith(members: updatedMembers));
  }
}
