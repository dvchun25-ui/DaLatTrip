import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:dalattrip/constants/app_colors.dart';
import '../../domain/entities/check_in_entry.dart';
import '../../domain/entities/check_in_member.dart';

class CheckInMemberCard extends StatefulWidget {
  final CheckInMember? member;
  final bool isCurrentUserSlot;
  final VoidCallback onTap;

  const CheckInMemberCard({
    super.key,
    required this.member,
    required this.isCurrentUserSlot,
    required this.onTap,
  });

  @override
  State<CheckInMemberCard> createState() => _CheckInMemberCardState();
}

class _CheckInMemberCardState extends State<CheckInMemberCard> {
  VideoPlayerController? _videoController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initVideoIfNeeded();
  }

  @override
  void didUpdateWidget(covariant CheckInMemberCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.member?.checkInEntry?.mediaPath !=
        oldWidget.member?.checkInEntry?.mediaPath) {
      _initVideoIfNeeded();
    }
  }

  void _initVideoIfNeeded() {
    final entry = widget.member?.checkInEntry;
    _videoController?.dispose();
    _videoController = null;

    if (entry != null &&
        entry.mediaType == CheckInMediaType.video &&
        entry.mediaPath.isNotEmpty &&
        File(entry.mediaPath).existsSync()) {
      _videoController = VideoPlayerController.file(File(entry.mediaPath))
        ..initialize().then((_) {
          if (mounted) setState(() {});
          _videoController?.setLooping(true);
          _videoController?.play();
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final entry = member?.checkInEntry;
    final hasEntry = entry != null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          height: 145,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: const Color(0xFF141F1A),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Background Content
                _buildCardBackground(entry),

                // 2. Gradient Overlay cho chữ hiển thị rõ nét
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.65),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),

                // 3. Header thông tin Avatar + Tên + Menu nút bấm
                Positioned(
                  top: 12,
                  left: 14,
                  right: 14,
                  child: Row(
                    children: [
                      // Avatar thành viên
                      _buildMemberAvatar(member),
                      const SizedBox(width: 10),
                      Text(
                        member?.displayName ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Spacer(),
                      if (hasEntry)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.ellipsis,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),

                // 4. Nội dung trung tâm (Giờ check-in lớn hoặc Nút + Mời bạn)
                Center(
                  child: hasEntry
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(entry.capturedAt),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF23362C).withValues(alpha: 0.8),
                                border: Border.all(
                                  color: const Color(0xFF81C784).withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                CupertinoIcons.add,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.isCurrentUserSlot ? 'Nhấn để chụp' : 'Mời bạn',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),

                // 5. Footer: Location chip + Video duration indicator
                if (hasEntry)
                  Positioned(
                    bottom: 12,
                    left: 14,
                    right: 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                CupertinoIcons.location_solid,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                entry.placeName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (entry.mediaType == CheckInMediaType.video)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  CupertinoIcons.play_fill,
                                  color: Colors.white,
                                  size: 11,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '0:03',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardBackground(CheckInEntry? entry) {
    if (entry != null) {
      if (entry.mediaType == CheckInMediaType.video &&
          _videoController != null &&
          _videoController!.value.isInitialized) {
        return FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _videoController!.value.size.width,
            height: _videoController!.value.size.height,
            child: VideoPlayer(_videoController!),
          ),
        );
      } else if (entry.mediaPath.isNotEmpty && File(entry.mediaPath).existsSync()) {
        return Image.file(
          File(entry.mediaPath),
          fit: BoxFit.cover,
        );
      } else {
        return Image.asset(
          'assets/images/dalat_splash_bg.jpg',
          fit: BoxFit.cover,
        );
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/dalat_splash_bg.jpg',
          fit: BoxFit.cover,
          color: Colors.black.withValues(alpha: 0.75),
          colorBlendMode: BlendMode.darken,
        ),
      ],
    );
  }

  Widget _buildMemberAvatar(CheckInMember? member) {
    if (member == null) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFF2A3A31),
        child: Icon(
          CupertinoIcons.person_fill,
          size: 20,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      );
    }

    final avatarPath = member.avatarPath;
    final hasLocalAvatar = avatarPath != null &&
        avatarPath.isNotEmpty &&
        File(avatarPath).existsSync();

    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primary,
      backgroundImage: hasLocalAvatar ? FileImage(File(avatarPath)) : null,
      child: !hasLocalAvatar
          ? Text(
              member.displayName.isNotEmpty
                  ? member.displayName[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            )
          : null,
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
