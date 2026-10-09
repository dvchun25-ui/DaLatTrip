import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:dalattrip/constants/app_colors.dart';
import '../../domain/entities/check_in_member.dart';
import '../../domain/entities/check_in_room.dart';
import '../../domain/repositories/check_in_repository.dart';
import '../../data/repositories/firebase_realtime_check_in_repository.dart';

class FriendPickerScreen extends StatefulWidget {
  final CheckInRoom room;
  final VoidCallback onRoomUpdated;

  const FriendPickerScreen({
    super.key,
    required this.room,
    required this.onRoomUpdated,
  });

  @override
  State<FriendPickerScreen> createState() => _FriendPickerScreenState();
}

class _FriendPickerScreenState extends State<FriendPickerScreen> {
  final CheckInRepository _repository =
      FirebaseRealtimeCheckInRepository.instance;
  final TextEditingController _searchController = TextEditingController();

  late CheckInRoom _currentRoom;

  // Danh sách gợi ý bạn bè mẫu Đà Lạt
  final List<CheckInMember> _mockFriends = const [
    CheckInMember(
      userId: 'linh_user',
      displayName: 'Linh',
      username: 'linh_dalat',
    ),
    CheckInMember(
      userId: 'phuc_user',
      displayName: 'Phúc',
      username: 'phuc_photo',
    ),
    CheckInMember(
      userId: 'trang_user',
      displayName: 'Trang',
      username: 'trang_dalat',
    ),
    CheckInMember(
      userId: 'nam_user',
      displayName: 'Nam',
      username: 'nam_coffee',
    ),
    CheckInMember(
      userId: 'hoa_user',
      displayName: 'Hoa',
      username: 'hoa_flower',
    ),
  ];

  List<CheckInMember> _filteredFriends = [];

  @override
  void initState() {
    super.initState();
    _currentRoom = widget.room;
    _filteredFriends = List.from(_mockFriends);
  }

  void _onSearch(String query) {
    final clean = query.trim().toLowerCase();
    setState(() {
      if (clean.isEmpty) {
        _filteredFriends = List.from(_mockFriends);
      } else {
        _filteredFriends = _mockFriends.where((f) {
          return f.displayName.toLowerCase().contains(clean) ||
              f.username.toLowerCase().contains(clean);
        }).toList();
      }
    });
  }

  Future<void> _toggleInvite(CheckInMember friend) async {
    final isAlreadyMember = _currentRoom.members.any(
      (m) => m.userId == friend.userId,
    );

    if (isAlreadyMember) {
      await _repository.removeMember(_currentRoom.id, friend.userId);
    } else {
      if (_currentRoom.members.length >= 4) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phòng đã đủ 4 thành viên'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
      await _repository.inviteMember(
        _currentRoom.id,
        friend.copyWith(status: CheckInMemberStatus.invited),
      );
    }

    final updated = await _repository.getRoomById(_currentRoom.id);
    if (updated != null && mounted) {
      setState(() => _currentRoom = updated);
      widget.onRoomUpdated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFull = _currentRoom.members.length >= 4;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1712), // Dark iOS Theme
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1712),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mời bạn vào phòng',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Thẻ cảnh báo khi phòng đã đủ 4 người
          if (isFull)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.shade900.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.shade700),
              ),
              child: const Row(
                children: [
                  Icon(
                    CupertinoIcons.info_circle_fill,
                    color: Colors.amber,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Phòng đã đủ 4 thành viên',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          // Ô tìm kiếm bạn bè
          Padding(
            padding: const EdgeInsets.all(16),
            child: CupertinoSearchTextField(
              controller: _searchController,
              onChanged: _onSearch,
              placeholder: 'Tìm kiếm tên hoặc username...',
              style: const TextStyle(color: Colors.white),
              backgroundColor: const Color(0xFF1B2822),
              borderRadius: BorderRadius.circular(14),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredFriends.length,
              itemBuilder: (context, index) {
                final friend = _filteredFriends[index];
                final memberMatch = _currentRoom.members.firstWhere(
                  (m) => m.userId == friend.userId,
                  orElse: () => const CheckInMember(
                    userId: '',
                    displayName: '',
                    username: '',
                  ),
                );

                final isMember = memberMatch.userId.isNotEmpty;
                final isInvited =
                    isMember &&
                    memberMatch.status == CheckInMemberStatus.invited;
                final isJoined =
                    isMember &&
                    memberMatch.status != CheckInMemberStatus.invited;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18251F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF2D3E35),
                        child: Text(
                          friend.displayName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              friend.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@${friend.username}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Nút Mời / Đã mời / Đã tham gia
                      if (isJoined)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A3E33),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Đã tham gia',
                            style: TextStyle(
                              color: Color(0xFF81C784),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else if (isInvited)
                        OutlinedButton(
                          onPressed: () => _toggleInvite(friend),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orangeAccent,
                            side: const BorderSide(color: Colors.orangeAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('Đã mời'),
                        )
                      else
                        FilledButton(
                          onPressed: isFull
                              ? null
                              : () => _toggleInvite(friend),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: Colors.grey.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('Mời'),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
