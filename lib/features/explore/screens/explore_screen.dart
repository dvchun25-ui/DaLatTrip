import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/category_mapper.dart';
import '../../../domain/entities/place.dart';
import '../../places/widgets/place_image.dart';
import '../controllers/explore_controller.dart';
import '../widgets/travel_category_grid.dart';
import 'place_detail_screen.dart';

/// Screen 2: Khám phá địa điểm.
class ExploreScreen extends StatefulWidget {
  final ExploreController? controller;
  final String? initialCategory;

  const ExploreScreen({
    super.key,
    this.controller,
    this.initialCategory,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final ExploreController _controller;
  late final bool _ownsController;
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? ExploreController();
    _controller.addListener(_onControllerChanged);
    _locationService.getCurrentLocation().then((_) {
      if (mounted) setState(() {});
    });
    _controller.loadPlaces().then((_) {
      if (widget.initialCategory != null && mounted) {
        _controller.filterByCategory(widget.initialCategory!);
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F5F3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _controller.searchPlaces,
            decoration: InputDecoration(
              hintText: 'Tìm địa điểm ở Đà Lạt...',
              hintStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.primary,
                size: 20,
              ),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _controller.searchPlaces('');
                      },
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          TravelCategoryGrid(
            selectedCategory: _controller.selectedCategory,
            onCategorySelected: (category) {
              if (category == null) {
                _controller.clearFilter();
                _searchController.clear();
              } else {
                _controller.filterByCategory(category);
              }
            },
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                _controller.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _controller.loadPlaces,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    if (_controller.filteredPlaces.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.explore_outlined,
                  size: 30,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Đang cập nhật thêm địa điểm',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Các địa điểm mới sẽ sớm được bổ sung.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _controller.filteredPlaces.length,
      itemBuilder: (context, index) {
        return _buildPlaceCard(_controller.filteredPlaces[index]);
      },
    );
  }

  Widget _buildPlaceCard(Place place) {
    final distance = _locationService.getDistanceToPlaceInKm(
      place.latitude,
      place.longitude,
    );

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlaceDetailScreen.fromPlace(place: place),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: PlaceImage(
                place: place,
                width: 105,
                height: 105,
                borderRadius: 0,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.favorite_border,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFFB300),
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          place.rating?.toStringAsFixed(1) ??
                              'Chưa có đánh giá',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mintBadge,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            CategoryMapper.displayName(place.categories.first),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatPrice(place),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.near_me_outlined,
                                size: 13,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  distance != null
                                      ? _locationService.formatDistance(distance)
                                      : (place.address ?? 'Đà Lạt'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: distance != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: distance != null
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(Place place) {
    if (place.priceMax <= 0) return 'Miễn phí';
    if (place.priceMin == place.priceMax) return _currency(place.priceMax);
    return '${_currency(place.priceMin)}–${_currency(place.priceMax)}';
  }

  String _currency(int value) {
    return '${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}đ';
  }
}
