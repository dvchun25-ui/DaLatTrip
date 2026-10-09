import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../core/utils/category_mapper.dart';
import '../../../domain/entities/trip_request.dart';

class TripRequestPreview extends StatelessWidget {
  final TripRequest request;

  const TripRequestPreview({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mintBadgeLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCFE2D7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.primary, size: 19),
              SizedBox(width: 7),
              Text(
                'Đã đủ thông tin',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _row('Thời gian', '${request.days} ngày'),
          _row('Số người', '${request.people} người'),
          _row('Ngân sách', _money(request.totalBudget)),
          _row(
            'Sở thích',
            request.interests.map(CategoryMapper.displayName).join(', '),
          ),
          _row('Di chuyển', _transport(request.transport)),
          _row('Nhịp độ', _pace(request.pace), isLast: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _money(int value) {
    return '${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')} VNĐ';
  }

  String _transport(String value) => switch (value) {
    'motorbike' => 'Xe máy',
    'car' => 'Ô tô',
    'taxi' => 'Taxi',
    'walking' => 'Đi bộ',
    _ => value,
  };

  String _pace(String value) => switch (value) {
    'relaxed' => 'Thư giãn',
    'packed' => 'Khám phá nhiều',
    _ => 'Cân bằng',
  };
}
