import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../core/constants/place_categories.dart';
import '../controllers/create_trip_controller.dart';
import 'itinerary_screen.dart';

/// Screen 4: Chọn sở thích
class PreferencesScreen extends StatefulWidget {
  final CreateTripController controller;

  const PreferencesScreen({super.key, required this.controller});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  late final Set<String> _selected;

  final List<Map<String, dynamic>> _activities = [
    {
      'name': 'Thiên nhiên',
      'value': PlaceCategories.nature,
      'icon': Icons.forest_outlined,
    },
    {
      'name': 'Cà phê',
      'value': PlaceCategories.cafe,
      'icon': Icons.coffee_outlined,
    },
    {
      'name': 'Check-in',
      'value': PlaceCategories.checkin,
      'icon': Icons.camera_alt_outlined,
    },
    {
      'name': 'Ẩm thực',
      'value': PlaceCategories.food,
      'icon': Icons.restaurant_outlined,
    },
    {
      'name': 'Khám phá',
      'value': PlaceCategories.adventure,
      'icon': Icons.explore_outlined,
    },
    {
      'name': 'Văn hóa',
      'value': PlaceCategories.culture,
      'icon': Icons.temple_buddhist_outlined,
    },
    {
      'name': 'Thư giãn',
      'value': PlaceCategories.relax,
      'icon': Icons.spa_outlined,
    },
    {
      'name': 'Gia đình',
      'value': PlaceCategories.family,
      'icon': Icons.family_restroom_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.controller.interests.isEmpty
        ? {PlaceCategories.nature, PlaceCategories.adventure}
        : widget.controller.interests.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Chọn sở thích',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Chọn các hoạt động bạn yêu thích để chúng tôi gợi ý phù hợp hơn',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
                childAspectRatio: 0.85,
              ),
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                final item = _activities[index];
                final name = item['name'] as String;
                final value = item['value'] as String;
                final icon = item['icon'] as IconData;
                final isSelected = _selected.contains(value);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selected.remove(value);
                      } else {
                        _selected.add(value);
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE8F2EC)
                          : const Color(0xFFF7FAF8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 1.8,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  icon,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Next button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  widget.controller.setInterests(_selected);
                  final error = widget.controller.validate();
                  if (error != null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error)));
                    return;
                  }
                  final request = widget.controller.createTripRequest();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ItineraryScreen(request: request),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Tiếp tục',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
