import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:dalattrip/constants/app_colors.dart';
import 'package:dalattrip/features/check_in/domain/entities/check_in_entry.dart';
import 'package:dalattrip/features/check_in/data/services/check_in_location_service.dart';
import '../widgets/check_in_location_chip.dart';
import 'check_in_recipient_screen.dart';

class CheckInPreviewScreen extends StatefulWidget {
  final String roomId;
  final String userId;
  final File mediaFile;
  final CheckInMediaType mediaType;
  final DateTime capturedAt;
  final CheckInLocationInfo locationInfo;
  final int durationSeconds;

  const CheckInPreviewScreen({
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
  State<CheckInPreviewScreen> createState() => _CheckInPreviewScreenState();
}

class _CheckInPreviewScreenState extends State<CheckInPreviewScreen> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.mediaType == CheckInMediaType.video) {
      _videoController = VideoPlayerController.file(widget.mediaFile)
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

  void _onNext() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => CheckInRecipientScreen(
          roomId: widget.roomId,
          userId: widget.userId,
          mediaFile: widget.mediaFile,
          mediaType: widget.mediaType,
          capturedAt: widget.capturedAt,
          locationInfo: widget.locationInfo,
          durationSeconds: widget.durationSeconds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildPreviewContent(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(CupertinoIcons.xmark, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                    CheckInLocationChip(
                      label: widget.locationInfo.formattedLabel,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              _formatTime(widget.capturedAt),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: FilledButton.icon(
                  onPressed: _onNext,
                  icon: const Icon(CupertinoIcons.arrow_right),
                  label: const Text('Tiếp tục'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent() {
    if (widget.mediaType == CheckInMediaType.video &&
        _videoController != null &&
        _videoController!.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    }
    return Image.file(
      widget.mediaFile,
      fit: BoxFit.cover,
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
