import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:dalattrip/constants/app_colors.dart';
import 'package:dalattrip/features/check_in/domain/entities/check_in_entry.dart';
import 'package:dalattrip/features/check_in/domain/entities/check_in_room.dart';
import 'package:dalattrip/features/check_in/domain/repositories/check_in_repository.dart';
import 'package:dalattrip/features/check_in/data/repositories/firebase_realtime_check_in_repository.dart';
import 'package:dalattrip/features/check_in/data/services/check_in_location_service.dart';
import 'package:dalattrip/features/check_in/data/services/check_in_media_service.dart';
import 'package:dalattrip/features/check_in/presentation/widgets/check_in_recipient_tile.dart';

class CheckInRecipientScreen extends StatefulWidget {
  final String roomId;
  final String userId;
  final File mediaFile;
  final CheckInMediaType mediaType;
  final DateTime capturedAt;
  final CheckInLocationInfo locationInfo;
  final int durationSeconds;

  const CheckInRecipientScreen({
    super.key,
    required this.roomId,
    required this.userId,
    required this.mediaFile,
    required this.mediaType,
    required this.capturedAt,
    required this.locationInfo,
    this.durationSeconds = 0,
  });

  @override
  State<CheckInRecipientScreen> createState() => _CheckInRecipientScreenState();
}

class _CheckInRecipientScreenState extends State<CheckInRecipientScreen> {
  final CheckInRepository _repository =
      FirebaseRealtimeCheckInRepository.instance;
  final CheckInMediaService _mediaService = CheckInMediaService.instance;

  CheckInRoom? _room;
  final Set<String> _selectedUserIds = {};
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadRoom();
  }

  Future<void> _loadRoom() async {
    final room = await _repository.getRoomById(widget.roomId);
    if (mounted && room != null) {
      setState(() {
        _room = room;
        _selectedUserIds.add(widget.userId);
        if (room.members.isNotEmpty) {
          _selectedUserIds.add(room.members.first.userId);
        }
      });
    }
  }

  void _toggleRecipient(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  Future<void> _sendCheckIn() async {
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 người nhận'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final checkInId = 'checkin_${DateTime.now().millisecondsSinceEpoch}';

      final savedMedia = await _mediaService.saveMedia(
        roomId: widget.roomId,
        userId: widget.userId,
        checkInId: checkInId,
        sourceFile: widget.mediaFile,
        mediaType: widget.mediaType,
        capturedAt: widget.capturedAt,
        durationSeconds: widget.durationSeconds,
      );

      final entry = CheckInEntry(
        id: checkInId,
        mediaPath: savedMedia.primaryPath,
        mediaUrl: savedMedia.mediaUrl,
        localMediaPath: savedMedia.localPath,
        mediaType: widget.mediaType,
        capturedAt: widget.capturedAt,
        latitude: widget.locationInfo.latitude,
        longitude: widget.locationInfo.longitude,
        placeId: widget.locationInfo.placeId,
        placeName: widget.locationInfo.placeName,
        durationSeconds: widget.durationSeconds,
        recipients: _selectedUserIds.toList(),
      );

      await _repository.saveCheckInEntry(
        roomId: widget.roomId,
        userId: widget.userId,
        entry: entry,
      );

      if (!savedMedia.uploaded && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã lưu check-in trên máy nhưng chưa tải được lên cloud. Hãy thử lại khi có mạng.',
            ),
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi gửi check-in: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = _room;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1712),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1712),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFF1B2822),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              CupertinoIcons.xmark,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text(
          'Gửi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 20,
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        CupertinoIcons.paperplane_fill,
                        color: Colors.white,
                        size: 18,
                      ),
                onPressed: _isSending ? null : _sendCheckIn,
              ),
            ),
          ),
        ],
      ),
      body: room == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Container(
                    height: 165,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: const Color(0xFF1B2822),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(widget.mediaFile, fit: BoxFit.cover),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.5),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.6),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              _formatTime(widget.capturedAt),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.location_solid,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.locationInfo.placeName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Gửi đến',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: room.members.length,
                    itemBuilder: (context, index) {
                      final member = room.members[index];
                      final isSelected = _selectedUserIds.contains(
                        member.userId,
                      );
                      return CheckInRecipientTile(
                        member: member,
                        isSelected: isSelected,
                        onToggle: (_) => _toggleRecipient(member.userId),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Đã chọn ${_selectedUserIds.length} người',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
