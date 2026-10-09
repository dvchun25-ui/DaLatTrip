import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:dalattrip/constants/app_colors.dart';
import 'package:dalattrip/features/check_in/domain/entities/check_in_member.dart';
import 'package:dalattrip/features/check_in/domain/entities/check_in_room.dart';
import 'package:dalattrip/features/check_in/domain/repositories/check_in_repository.dart';
import 'package:dalattrip/features/check_in/data/repositories/local_check_in_repository.dart';

import '../widgets/check_in_member_card.dart';
import 'check_in_camera_screen.dart';
import 'friend_picker_screen.dart';

/// Màn hình Phòng Check-in Nhóm (CheckInRoomScreen) đặt trực tiếp tại Tab Check-in
class CheckInRoomScreen extends StatefulWidget {
  const CheckInRoomScreen({super.key});

  @override
  State<CheckInRoomScreen> createState() => _CheckInRoomScreenState();
}

class _CheckInRoomScreenState extends State<CheckInRoomScreen> {
  final CheckInRepository _repository = LocalCheckInRepository.instance;

  CheckInRoom? _currentRoom;
  bool _isLoading = true;
  bool _showSuccessToast = false;

  // Giả lập user ID hiện tại của ứng dụng
  static const String _currentUserId = 'chung_user';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final rooms = await _repository.getRooms();
    if (mounted) {
      setState(() {
        _currentRoom = rooms.firstOrNull;
        _isLoading = false;
      });
    }
  }

  void _triggerSuccessToast() {
    setState(() => _showSuccessToast = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSuccessToast = false);
    });
  }

  void _onCardTapped(int slotIndex, CheckInMember? member) async {
    final room = _currentRoom;
    if (room == null) return;

    final isOwnerOrMe = member?.userId == _currentUserId || slotIndex == 0;

    if (isOwnerOrMe) {
      await Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => CheckInCameraScreen(
            roomId: room.id,
            userId: _currentUserId,
          ),
        ),
      );
      await _loadData();
      _triggerSuccessToast();
    } else if (member == null || member.status == CheckInMemberStatus.invited) {
      await Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => FriendPickerScreen(
            room: room,
            onRoomUpdated: _loadData,
          ),
        ),
      );
      await _loadData();
    } else {
      if (member.checkInEntry != null) {
        _showMemberDetailSheet(member);
      }
    }
  }

  void _showMemberDetailSheet(CheckInMember member) {
    final entry = member.checkInEntry;
    if (entry == null) return;

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: Text('Check-in của ${member.displayName}'),
          message: Text('${entry.placeName} • ${_formatTime(entry.capturedAt)}'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Xem ảnh full màn hình'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final room = _currentRoom;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1712), // Nền tối xanh đen chuẩn iOS
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderBar(room),
            const SizedBox(height: 8),

            if (_showSuccessToast) ...[
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showSuccessToast ? 1.0 : 0.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF263D31),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF81C784).withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.checkmark_alt_circle_fill, color: Color(0xFF81C784), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Đã gửi check-in',
                        style: TextStyle(
                          color: Color(0xFF81C784),
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : room == null
                      ? const Center(
                          child: Text(
                            'Chưa có phòng check-in nào',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: 4,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final member = (index < room.members.length)
                                ? room.members[index]
                                : null;
                            final isMe = index == 0 || member?.userId == _currentUserId;

                            return CheckInMemberCard(
                              member: member,
                              isCurrentUserSlot: isMe,
                              onTap: () => _onCardTapped(index, member),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBar(CheckInRoom? room) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIconButton(
                icon: CupertinoIcons.chevron_left,
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIconButton(
                    icon: CupertinoIcons.calendar,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B2822),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          room?.name ?? 'log',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          CupertinoIcons.chevron_down,
                          color: Colors.white70,
                          size: 13,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIconButton(
                    icon: CupertinoIcons.share,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(
                    icon: CupertinoIcons.chat_bubble,
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          CustomPaint(
            size: const Size(22, 18),
            painter: _HeaderMascotPainter(),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF81C784),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF1B2822),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 18),
        padding: EdgeInsets.zero,
        onPressed: onTap,
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _HeaderMascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF81C784)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.5, 2)
      ..lineTo(size.width * 0.1, size.height)
      ..lineTo(size.width * 0.9, size.height)
      ..close();

    canvas.drawPath(path, paint);

    final flowerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width * 0.5, 2), 2, flowerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
