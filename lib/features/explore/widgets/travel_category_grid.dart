import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../core/constants/place_categories.dart';

/// Class định nghĩa thông tin cho một danh mục du lịch
class TravelCategory {
  final String label;
  final IconData icon;
  final String category;
  final bool enabled;

  const TravelCategory({
    required this.label,
    required this.icon,
    required this.category,
    this.enabled = true,
  });
}

/// Danh sách 8 danh mục du lịch chính của DaLatTrip (Single Source of Truth)
const List<TravelCategory> travelCategories = [
  TravelCategory(
    label: 'Tham quan',
    icon: Icons.landscape_outlined,
    category: PlaceCategories.attraction,
  ),
  TravelCategory(
    label: 'Ăn uống',
    icon: Icons.restaurant_outlined,
    category: PlaceCategories.food,
  ),
  TravelCategory(
    label: 'Quán cafe',
    icon: Icons.local_cafe_outlined,
    category: PlaceCategories.cafe,
  ),
  TravelCategory(
    label: 'Check-in',
    icon: Icons.camera_alt_outlined,
    category: PlaceCategories.checkin,
  ),
  TravelCategory(
    label: 'Thiên nhiên',
    icon: Icons.forest_outlined,
    category: PlaceCategories.nature,
  ),
  TravelCategory(
    label: 'Văn hóa',
    icon: Icons.museum_outlined,
    category: PlaceCategories.culture,
  ),
  TravelCategory(
    label: 'Vui chơi',
    icon: Icons.attractions_outlined,
    category: PlaceCategories.entertainment,
  ),
  TravelCategory(
    label: 'Khách sạn',
    icon: Icons.hotel_outlined,
    category: PlaceCategories.hotel,
  ),
];

/// Item danh mục thiết kế chuẩn iOS modern, có hiệu ứng scale nhẹ khi chạm.
class TravelCategoryItem extends StatefulWidget {
  final TravelCategory item;
  final bool isSelected;
  final ValueChanged<TravelCategory> onTap;

  const TravelCategoryItem({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<TravelCategoryItem> createState() => _TravelCategoryItemState();
}

class _TravelCategoryItemState extends State<TravelCategoryItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap(widget.item);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Container icon chuẩn iOS bo góc mềm mại 15px
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : const Color(0xFFF2F7F4), // Nền xanh rêu nhạt chuẩn Đà Lạt
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFE5EFEA),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.03),
                    blurRadius: isSelected ? 8 : 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                widget.item.icon,
                size: 23,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            // Tên danh mục bên dưới căn giữa
            Text(
              widget.item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lưới 4 cột × 2 hàng hiển thị các danh mục du lịch
class TravelCategoryGrid extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;
  final bool showHeader;

  const TravelCategoryGrid({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHeader) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Khám phá theo sở thích',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                InkWell(
                  onTap: () => onCategorySelected(null),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      selectedCategory == null ? 'Tất cả' : 'Bỏ lọc',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          // Layout 4 cột x 2 hàng với khoảng cách vừa phải, không bị overflow
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: travelCategories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final cat = travelCategories[index];
              final isSelected = selectedCategory == cat.category;
              return TravelCategoryItem(
                item: cat,
                isSelected: isSelected,
                onTap: (item) {
                  if (isSelected) {
                    onCategorySelected(null);
                  } else {
                    onCategorySelected(item.category);
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
