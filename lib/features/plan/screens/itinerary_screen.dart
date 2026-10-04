import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import 'route_map_screen.dart';
import 'budget_screen.dart';

/// Screen 5: Lịch trình gợi ý theo ngày
class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  int _selectedDay = 1;

  final List<Map<String, dynamic>> _timelineDay1 = [
    {
      'time': '07:00 - 08:30',
      'title': 'Săn mây Cầu Đất',
      'info': '24 km • 40 phút',
      'image': 'assets/images/dalat_splash_bg.jpg',
      'type': 'place',
    },
    {
      'time': '08:30 - 09:30',
      'title': 'Ăn sáng tại Cầu Đất',
      'info': 'Bánh mì xíu mại, sữa đậu nành nóng',
      'type': 'food',
    },
    {
      'time': '10:00 - 11:30',
      'title': 'Đồi chè Cầu Đất',
      'info': '⭐ 4.5 • Miễn phí',
      'image': 'assets/images/dalat_splash_bg.jpg',
      'type': 'place',
    },
    {
      'time': '12:00 - 13:30',
      'title': 'Ăn trưa',
      'info': 'Lẩu gà lá é Tao Ngộ',
      'type': 'food',
    },
    {
      'time': '14:00 - 15:30',
      'title': 'Quán cafe The Diff House',
      'info': '⭐ 4.6 • 50.000đ - 150.000đ',
      'image': 'assets/images/dalat_glasshouse.jpg',
      'type': 'place',
    },
    {
      'time': '16:00 - 17:30',
      'title': 'Ngắm hoàng hôn Hồ Tuyền Lâm',
      'info': '⭐ 4.8 • Miễn phí',
      'image': 'assets/images/dalat_splash_bg.jpg',
      'type': 'place',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Lịch trình gợi ý',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Day Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _buildDayTab(1, 'Ngày 1'),
                const SizedBox(width: 10),
                _buildDayTab(2, 'Ngày 2'),
                const SizedBox(width: 10),
                _buildDayTab(3, 'Ngày 3'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Timeline List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _timelineDay1.length,
              itemBuilder: (context, index) {
                final item = _timelineDay1[index];
                return _buildTimelineItem(item, index == _timelineDay1.length - 1);
              },
            ),
          ),

          // Bottom Bar with Map & Budget buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RouteMapScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Bản đồ lộ trình'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BudgetScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.pie_chart_outline, size: 18, color: AppColors.primary),
                    label: const Text('Dự toán chi phí'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTab(int day, String title) {
    final isSelected = _selectedDay == day;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDay = day),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : const Color(0xFFF2F6F3),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> item, bool isLast) {
    final isPlace = item['type'] == 'place';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator line
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isPlace ? AppColors.primary : const Color(0xFFF57C00),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlace ? Icons.location_on : Icons.restaurant,
                  color: Colors.white,
                  size: 13,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFD4E2D8),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Timeline content card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['time'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isPlace ? AppColors.primary : const Color(0xFFF57C00),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['info'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.containsKey('image')) ...[
                    const SizedBox(width: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        item['image'] as String,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60,
                          height: 60,
                          color: const Color(0xFFC8DEC9),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
