import '../entities/check_in_entry.dart';
import '../entities/check_in_member.dart';
import '../entities/check_in_room.dart';

abstract class CheckInRepository {
  Future<CheckInRoom> createRoom({
    required String name,
    required String ownerId,
    required CheckInMember ownerMember,
  });

  Future<List<CheckInRoom>> getRooms();

  Future<CheckInRoom?> getRoomById(String id);

  Future<void> updateRoom(CheckInRoom room);

  Future<void> inviteMember(String roomId, CheckInMember member);

  Future<void> removeMember(String roomId, String userId);

  Future<void> saveCheckInEntry({
    required String roomId,
    required String userId,
    required CheckInEntry entry,
  });

  Future<void> replaceCheckInEntry({
    required String roomId,
    required String userId,
    required CheckInEntry entry,
  });

  Future<void> deleteCheckInEntry({
    required String roomId,
    required String userId,
  });
}
