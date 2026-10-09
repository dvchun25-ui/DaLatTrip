import 'package:flutter/material.dart';

class CheckInCameraButton extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;
  final double videoProgress;

  const CheckInCameraButton({
    super.key,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    this.videoProgress = 0.0,
  });

  @override
  State<CheckInCameraButton> createState() => _CheckInCameraButtonState();
}

class _CheckInCameraButtonState extends State<CheckInCameraButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      onLongPressStart: (_) {
        setState(() => _isPressed = true);
        widget.onLongPressStart();
      },
      onLongPressEnd: (_) {
        setState(() => _isPressed = false);
        widget.onLongPressEnd();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: SizedBox(
          width: 82,
          height: 82,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Vòng tròn đếm giờ video (khi đang giữ quay)
              if (widget.videoProgress > 0)
                SizedBox(
                  width: 82,
                  height: 82,
                  child: CircularProgressIndicator(
                    value: widget.videoProgress,
                    strokeWidth: 4,
                    color: Colors.redAccent,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                  ),
                ),

              // Vòng tròn outer green nhạt phong cách Đà Lạt
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFC8E6C9),
                    width: 3.5,
                  ),
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),

              // Nút bấm trung tâm chứa linh vật / nút shutter
              Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE8F5E9),
                ),
                child: Center(
                  child: widget.videoProgress > 0
                      ? Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        )
                      : CustomPaint(
                          size: const Size(36, 32),
                          painter: _CuteMascotPainter(),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Painter vẽ linh vật núi Đà Lạt đội hoa xinh xắn (Matching Screenshot 2 & 4)
class _CuteMascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF81C784)
      ..style = PaintingStyle.fill;

    // Hình nón/núi xanh
    final path = Path()
      ..moveTo(size.width * 0.5, 6)
      ..cubicTo(
        size.width * 0.2,
        size.height * 0.4,
        size.width * 0.05,
        size.height * 0.85,
        size.width * 0.1,
        size.height * 0.95,
      )
      ..lineTo(size.width * 0.9, size.height * 0.95)
      ..cubicTo(
        size.width * 0.95,
        size.height * 0.85,
        size.width * 0.8,
        size.height * 0.4,
        size.width * 0.5,
        6,
      )
      ..close();

    canvas.drawPath(path, paint);

    // Mắt đen nhỏ xinh
    final eyePaint = Paint()..color = const Color(0xFF1B4332);
    canvas.drawCircle(Offset(size.width * 0.38, size.height * 0.6), 2, eyePaint);
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.6), 2, eyePaint);

    // Nụ cười mỉm
    final mouthPaint = Paint()
      ..color = const Color(0xFF1B4332)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path()
      ..moveTo(size.width * 0.44, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.8,
        size.width * 0.56,
        size.height * 0.72,
      );
    canvas.drawPath(mouthPath, mouthPaint);

    // Bông hoa nhỏ đỉnh đầu
    final flowerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width * 0.5, 4), 3, flowerPaint);
    final centerPaint = Paint()..color = Colors.amber;
    canvas.drawCircle(Offset(size.width * 0.5, 4), 1.2, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
