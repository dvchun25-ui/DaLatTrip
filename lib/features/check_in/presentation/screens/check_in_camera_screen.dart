import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:dalattrip/features/check_in/domain/entities/check_in_entry.dart';
import 'package:dalattrip/features/check_in/data/services/check_in_location_service.dart';
import '../widgets/check_in_camera_button.dart';
import '../widgets/check_in_location_chip.dart';
import 'check_in_preview_screen.dart';

class CheckInCameraScreen extends StatefulWidget {
  final String roomId;
  final String userId;

  const CheckInCameraScreen({
    super.key,
    required this.roomId,
    required this.userId,
  });

  @override
  State<CheckInCameraScreen> createState() => _CheckInCameraScreenState();
}

class _CheckInCameraScreenState extends State<CheckInCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isPermissionDenied = false;
  bool _isCameraInitializing = true;
  bool _isCameraOperationInProgress = false;
  bool _isTakingPicture = false;
  String? _cameraError;
  FlashMode _flashMode = FlashMode.off;

  final ImagePicker _picker = ImagePicker();
  final CheckInLocationService _locationService = CheckInLocationService.instance;

  CheckInLocationInfo _locationInfo = const CheckInLocationInfo(
    placeName: 'Hồ Xuân Hương, Đà Lạt',
    formattedLabel: '📍 Hồ Xuân Hương · Đà Lạt',
  );

  bool _isRecording = false;
  double _videoProgress = 0.0;
  Timer? _videoTimer;
  DateTime _currentTime = DateTime.now();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initClock();
    _initLocation();
    _requestPermissionsAndInitCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed &&
        _cameraController == null) {
      _requestPermissionsAndInitCamera();
    }
  }

  void _initClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  Future<void> _initLocation() async {
    final info = await _locationService.getCurrentCheckInLocation();
    if (mounted) setState(() => _locationInfo = info);
  }

  Future<void> _requestPermissionsAndInitCamera() async {
    if (_isCameraOperationInProgress) return;
    _isCameraOperationInProgress = true;
    if (mounted) {
      setState(() {
        _isCameraInitializing = true;
        _cameraError = null;
      });
    }

    if (mounted) {
      setState(() => _isPermissionDenied = false);
    }
    try {
      // CameraController sẽ hiển thị hộp thoại quyền hệ thống khi initialize.
      await _initCamera();
    } finally {
      _isCameraOperationInProgress = false;
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        final backCameraIndex = _cameras.indexWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
        );
        _selectedCameraIndex = backCameraIndex < 0 ? 0 : backCameraIndex;
        await _setupCameraController(_cameras[_selectedCameraIndex]);
      } else {
        _setCameraError('Thiết bị không tìm thấy camera để sử dụng.');
      }
    } on CameraException catch (e) {
      debugPrint('Không khởi tạo được camera phần cứng: $e');
      _handleCameraException(e);
    } catch (e) {
      debugPrint('Không khởi tạo được camera phần cứng: $e');
      _setCameraError('Không thể mở camera. Vui lòng thử lại.');
    }
  }

  Future<void> _setupCameraController(
    CameraDescription camera, {
    bool enableAudio = true,
  }) async {
    final oldController = _cameraController;
    _cameraController = null;
    await oldController?.dispose();

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        _isCameraInitializing = false;
        _cameraError = null;
        _flashMode = FlashMode.off;
      });
    } on CameraException catch (e) {
      await controller.dispose();
      debugPrint('Lỗi setup camera controller: $e');
      if (enableAudio && e.code.startsWith('AudioAccess')) {
        // Người dùng vẫn có thể chụp ảnh và quay video không tiếng khi không
        // cấp quyền micro; quyền micro không được làm hỏng toàn bộ camera.
        await _setupCameraController(camera, enableAudio: false);
        return;
      }
      _handleCameraException(e);
    } catch (e) {
      await controller.dispose();
      debugPrint('Lỗi setup camera controller: $e');
      _setCameraError('Không thể mở camera. Vui lòng thử lại.');
    }
  }

  void _handleCameraException(CameraException error) {
    final permissionError = error.code == 'CameraAccessDenied' ||
        error.code == 'CameraAccessDeniedWithoutPrompt' ||
        error.code == 'CameraAccessRestricted';
    if (!mounted) return;
    setState(() {
      _isPermissionDenied = permissionError;
      _isCameraInitializing = false;
      _cameraError = permissionError
          ? null
          : 'Không thể mở camera (${error.description ?? error.code}).';
    });
  }

  void _setCameraError(String message) {
    if (!mounted) return;
    setState(() {
      _isCameraInitializing = false;
      _cameraError = message;
    });
  }

  Future<void> _disposeCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) await controller.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final nextMode = _flashMode == FlashMode.off ? FlashMode.always : FlashMode.off;
      await _cameraController!.setFlashMode(nextMode);
      if (mounted) setState(() => _flashMode = nextMode);
    } catch (e) {
      debugPrint('Lỗi bật/tắt flash: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 ||
        _isCameraInitializing ||
        _isCameraOperationInProgress) {
      return;
    }
    _isCameraOperationInProgress = true;
    setState(() => _isCameraInitializing = true);
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _setupCameraController(_cameras[_selectedCameraIndex]);
    _isCameraOperationInProgress = false;
  }

  Future<void> _takePhoto() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isTakingPicture) {
      _showCameraMessage('Camera chưa sẵn sàng. Vui lòng thử lại.');
      return;
    }

    _isTakingPicture = true;
    try {
      final file = await controller.takePicture();
      if (!mounted) return;

      _navigateToPreview(
        file: File(file.path),
        mediaType: CheckInMediaType.photo,
        durationSeconds: 0,
      );
    } on CameraException catch (e) {
      debugPrint('Lỗi chụp ảnh camera: $e');
      _showCameraMessage('Không thể chụp ảnh. Vui lòng thử lại.');
    } finally {
      _isTakingPicture = false;
    }
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      _showCameraMessage('Camera chưa sẵn sàng. Vui lòng thử lại.');
      return;
    }

    try {
      await controller.startVideoRecording();
    } on CameraException catch (e) {
      debugPrint('Lỗi bắt đầu quay video: $e');
      _showCameraMessage('Không thể quay video. Vui lòng thử lại.');
      return;
    }

    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _videoProgress = 0.0;
    });

    const intervalMs = 50;
    const maxMs = 3000;
    int elapsedMs = 0;

    _videoTimer?.cancel();
    _videoTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      elapsedMs += intervalMs;
      if (mounted) {
        setState(() {
          _videoProgress = (elapsedMs / maxMs).clamp(0.0, 1.0);
        });
      }
      if (elapsedMs >= maxMs) {
        timer.cancel();
        _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    _videoTimer?.cancel();
    setState(() => _isRecording = false);

    File? videoFile;
    if (_cameraController != null &&
        _cameraController!.value.isRecordingVideo) {
      try {
        final xfile = await _cameraController!.stopVideoRecording();
        videoFile = File(xfile.path);
      } catch (e) {
        debugPrint('Lỗi dừng video: $e');
      }
    }

    if (videoFile != null && mounted) {
      _navigateToPreview(
        file: videoFile,
        mediaType: CheckInMediaType.video,
        durationSeconds: 3,
      );
    }
  }

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      _navigateToPreview(
        file: File(picked.path),
        mediaType: CheckInMediaType.photo,
        durationSeconds: 0,
      );
    }
  }

  void _showCameraMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _navigateToPreview({
    required File file,
    required CheckInMediaType mediaType,
    required int durationSeconds,
  }) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => CheckInPreviewScreen(
          roomId: widget.roomId,
          userId: widget.userId,
          mediaFile: file,
          mediaType: mediaType,
          capturedAt: _currentTime,
          locationInfo: _locationInfo,
          durationSeconds: durationSeconds,
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    _videoTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildCameraPreview(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
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
                          icon: const Icon(CupertinoIcons.chevron_left, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                    CheckInLocationChip(
                      label: _locationInfo.formattedLabel,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _flashMode == FlashMode.always ? CupertinoIcons.bolt_fill : CupertinoIcons.bolt_slash_fill,
                            color: _flashMode == FlashMode.always ? Colors.yellow : Colors.white,
                          ),
                          onPressed: _toggleFlash,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(_currentTime),
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
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Nhấn để chụp · Giữ để quay tối đa 3s',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 32, right: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(CupertinoIcons.switch_camera, color: Colors.white, size: 24),
                        onPressed: _switchCamera,
                      ),
                    ),
                    CheckInCameraButton(
                      onTap: _takePhoto,
                      onLongPressStart: _startRecording,
                      onLongPressEnd: _stopRecording,
                      videoProgress: _videoProgress,
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(CupertinoIcons.photo, color: Colors.white, size: 22),
                        onPressed: _pickFromGallery,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_isPermissionDenied) {
      return Container(
        color: const Color(0xFF0F1712),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.camera_fill,
              size: 64,
              color: Color(0xFF81C784),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cần quyền truy cập Máy ảnh',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'DALATTRIP cần quyền truy cập camera và micro của thiết bị để chụp ảnh/quay video check-in cùng bạn bè.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CupertinoButton(
              color: const Color(0xFF81C784),
              borderRadius: BorderRadius.circular(24),
              onPressed: _requestPermissionsAndInitCamera,
              child: const Text(
                'Thử lại sau khi cấp quyền',
                style: TextStyle(
                  color: Color(0xFF0F1712),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_cameraError != null) {
      return _buildCameraStatus(
        icon: CupertinoIcons.exclamationmark_triangle_fill,
        title: 'Không thể mở camera',
        message: _cameraError!,
        actionLabel: 'Thử lại',
        onPressed: _requestPermissionsAndInitCamera,
      );
    }

    if (_isCameraInitializing) {
      return const ColoredBox(
        color: Color(0xFF0F1712),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF81C784)),
        ),
      );
    }

    if (_cameraController != null && _cameraController!.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize?.height ?? 1,
          height: _cameraController!.value.previewSize?.width ?? 1,
          child: CameraPreview(_cameraController!),
        ),
      );
    }
    return _buildCameraStatus(
      icon: CupertinoIcons.camera_fill,
      title: 'Camera chưa sẵn sàng',
      message: 'Hãy thử mở lại camera để tiếp tục check-in.',
      actionLabel: 'Mở camera',
      onPressed: _requestPermissionsAndInitCamera,
    );
  }

  Widget _buildCameraStatus({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onPressed,
  }) {
    return ColoredBox(
      color: const Color(0xFF0F1712),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 58, color: const Color(0xFF81C784)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 24),
            CupertinoButton(
              color: const Color(0xFF81C784),
              onPressed: onPressed,
              child: Text(
                actionLabel,
                style: const TextStyle(
                  color: Color(0xFF0F1712),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
