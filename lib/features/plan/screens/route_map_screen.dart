import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

/// Screen 6: Bản đồ lộ trình
class RouteMapScreen extends StatefulWidget {
  const RouteMapScreen({super.key});

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  int _selectedDay = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Bản đồ lộ trình',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Simulated Topo Map graphic
          Positioned.fill(
            child: Container(
              color: const Color(0xFFE9F1EC),
              child: CustomPaint(
                painter: _MapCanvasPainter(),
              ),
            ),
          ),

          // Top Floating Section: Day tabs & metrics summary
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Day Tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildDayOption(1, 'Ngày 1'),
                      _buildDayOption(2, 'Ngày 2'),
                      _buildDayOption(3, 'Ngày 3'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Metrics summary
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: const [
                          Text('Tổng quãng đường', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          SizedBox(height: 2),
                          Text('56 km', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        ],
                      ),
                      Container(height: 24, width: 1, color: AppColors.divider),
                      Column(
                        children: const [
                          Text('Thời gian di chuyển', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          SizedBox(height: 2),
                          Text('~ 2 giờ 10 phút', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating Card for current active route waypoint
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/dalat_splash_bg.jpg',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '1',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'Săn mây Cầu Đất',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '07:00 - 08:30',
                          style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '📍 24 km • 40 phút',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayOption(int day, String label) {
    final isSelected = _selectedDay == day;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDay = day),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintRoute = Paint()
      ..color = const Color(0xFF2D6A4F)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.25, size.height * 0.35);
    path.quadraticBezierTo(size.width * 0.45, size.height * 0.38, size.width * 0.65, size.height * 0.42);
    path.quadraticBezierTo(size.width * 0.85, size.height * 0.46, size.width * 0.75, size.height * 0.65);
    path.quadraticBezierTo(size.width * 0.65, size.height * 0.75, size.width * 0.35, size.height * 0.80);

    canvas.drawPath(path, paintRoute);

    // Waypoints
    _drawMarker(canvas, Offset(size.width * 0.25, size.height * 0.35), '1');
    _drawMarker(canvas, Offset(size.width * 0.65, size.height * 0.42), '2');
    _drawMarker(canvas, Offset(size.width * 0.75, size.height * 0.65), '3');
    _drawMarker(canvas, Offset(size.width * 0.35, size.height * 0.80), '4');
  }

  void _drawMarker(Canvas canvas, Offset offset, String text) {
    final bgPaint = Paint()..color = const Color(0xFF1E3A2F);
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(offset, 14, bgPaint);
    canvas.drawCircle(offset, 14, borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(offset.dx - textPainter.width / 2, offset.dy - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
