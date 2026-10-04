import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

/// Screen 9: Gợi ý theo thời tiết
class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

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
          'Gợi ý theo thời tiết',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: const [
                Icon(Icons.wb_sunny_outlined, color: Color(0xFFFFA000), size: 18),
                SizedBox(width: 8),
                Text(
                  'Thời tiết tại Đà Lạt: 15/12 - 17/12',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3 Days Forecast Cards
            Row(
              children: [
                _buildWeatherDay('Ngày 1', '22°', 'Nhiều mây', Icons.cloud_outlined),
                const SizedBox(width: 10),
                _buildWeatherDay('Ngày 2', '18°', 'Mưa nhẹ', Icons.grain_outlined, isRain: true),
                const SizedBox(width: 10),
                _buildWeatherDay('Ngày 3', '20°', 'Nắng nhẹ', Icons.wb_sunny_outlined),
              ],
            ),
            const SizedBox(height: 20),

            // Weather Warning Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.umbrella_outlined, color: Color(0xFFD32F2F), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Ngày 2 có khả năng mưa',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Chúng tôi gợi ý các hoạt động trong nhà phù hợp với thời tiết mưa để bạn vẫn có một trải nghiệm tuyệt vời.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Gợi ý hoạt động
            const Text(
              'Gợi ý hoạt động ngày mưa',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildActivityChip('Tham quan\nbảo tàng', Icons.museum_outlined),
                const SizedBox(width: 10),
                _buildActivityChip('Cafe view\nđẹp', Icons.local_cafe_outlined),
                const SizedBox(width: 10),
                _buildActivityChip('Mua sắm\nđặc sản', Icons.shopping_basket_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDay(String day, String temp, String status, IconData icon, {bool isRain = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isRain ? const Color(0xFFFFF1F0) : const Color(0xFFF7FAF8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRain ? const Color(0xFFFFCDD2) : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Text(day, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Icon(icon, color: isRain ? const Color(0xFF1E88E5) : const Color(0xFFFFA000), size: 28),
            const SizedBox(height: 8),
            Text(temp, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(status, style: TextStyle(fontSize: 11, color: isRain ? const Color(0xFFD32F2F) : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityChip(String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F6F3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
