import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../core/utils/category_mapper.dart';
import '../../../domain/entities/place.dart';
import '../../../models/travel_models.dart';
import '../../places/widgets/place_image.dart';

class _PlaceDetailData {
  final Place domainPlace;
  final String title;
  final String ratingLabel;
  final String reviewCount;
  final String category;
  final String price;
  final String distance;
  final String description;
  final bool isFavorite;

  const _PlaceDetailData({
    required this.domainPlace,
    required this.title,
    required this.ratingLabel,
    required this.reviewCount,
    required this.category,
    required this.price,
    required this.distance,
    required this.description,
    required this.isFavorite,
  });

  factory _PlaceDetailData.fromLegacy(PlaceItem place) {
    final domainPlace = Place(
      id: place.id,
      name: place.title,
      categories: [CategoryMapper.normalize(place.category) ?? 'checkin'],
      description: place.description,
      priceMin: 0,
      priceMax: 0,
      visitDurationMinutes: 90,
      rating: place.rating,
      indoor: false,
      imageUrl: place.image,
    );
    return _PlaceDetailData(
      domainPlace: domainPlace,
      title: place.title,
      ratingLabel: place.rating.toStringAsFixed(1),
      reviewCount: place.reviewCount,
      category: place.category,
      price: place.price,
      distance: place.distance,
      description: place.description,
      isFavorite: place.isFavorite,
    );
  }

  factory _PlaceDetailData.fromPlace(Place place) {
    return _PlaceDetailData(
      domainPlace: place,
      title: place.name,
      ratingLabel: place.rating?.toStringAsFixed(1) ?? 'Chưa có',
      reviewCount: place.rating == null ? 'chưa có' : 'dataset',
      category: place.categories.map(CategoryMapper.displayName).join(', '),
      price: _formatPrice(place.priceMin, place.priceMax),
      distance: place.address ?? 'Đà Lạt',
      description: place.description ?? 'Chưa có mô tả cho địa điểm này.',
      isFavorite: false,
    );
  }

  static String _formatPrice(int min, int max) {
    if (max <= 0) return 'Miễn phí';
    String currency(int value) =>
        '${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}đ';
    if (min == max) return currency(max);
    return '${currency(min)}–${currency(max)}';
  }
}

/// Screen 8: Chi tiết địa điểm (Hồ Tuyền Lâm, v.v.)
class PlaceDetailScreen extends StatefulWidget {
  final _PlaceDetailData _place;

  PlaceDetailScreen({super.key, required PlaceItem place})
    : _place = _PlaceDetailData.fromLegacy(place);

  PlaceDetailScreen.fromPlace({super.key, required Place place})
    : _place = _PlaceDetailData.fromPlace(place);

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFav = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _isFav = widget._place.isFavorite;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final place = widget._place;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero Image Header with AppBar
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isFav ? Icons.favorite : Icons.favorite_border,
                        color: _isFav ? const Color(0xFFE53935) : Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isFav = !_isFav;
                        });
                      },
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      PlaceImage(
                        place: place.domainPlace,
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: 0,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        place.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Rating & metadata badges
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Color(0xFFFFB300),
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${place.ratingLabel} (${place.reviewCount} đánh giá)',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 8,
                        children: [
                          _buildTag(Icons.park, place.category),
                          _buildTag(Icons.confirmation_number, place.price),
                          _buildTag(Icons.location_on, place.distance),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Tabs: Giới thiệu | Hình ảnh | Đánh giá | Gần đây
                      TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 3,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                        tabs: const [
                          Tab(text: 'Giới thiệu'),
                          Tab(text: 'Hình ảnh'),
                          Tab(text: 'Đánh giá'),
                          Tab(text: 'Gần đây'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tab Content
                      Text(
                        place.description,
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Đọc thêm ➔',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Highlight highlights
                      const Text(
                        'Điểm nổi bật',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildHighlightItem(
                        Icons.nature_people,
                        'Chèo thuyền Kayak & SUP ngắm bình minh',
                      ),
                      _buildHighlightItem(
                        Icons.camera_alt,
                        'Check-in rừng thông ngập nước thơ mộng',
                      ),
                      _buildHighlightItem(
                        Icons.coffee,
                        'Nhiều quán cafe chill ven bờ hồ',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Fixed Action Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.navigation_outlined, size: 18),
                      label: const Text('Chỉ đường'),
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
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isFav = !_isFav;
                      });
                    },
                    icon: Icon(
                      _isFav ? Icons.favorite : Icons.favorite_border,
                      color: _isFav
                          ? const Color(0xFFE53935)
                          : AppColors.primary,
                      size: 18,
                    ),
                    label: Text(
                      _isFav ? 'Đã lưu' : 'Lưu vào yêu thích',
                      style: TextStyle(
                        color: _isFav
                            ? const Color(0xFFE53935)
                            : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _isFav
                            ? const Color(0xFFE53935)
                            : AppColors.primary,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.mintBadge,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.mintBadge,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
