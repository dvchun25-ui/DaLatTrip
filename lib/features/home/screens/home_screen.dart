import 'package:flutter/material.dart';
import 'package:dalattrip/constants/app_colors.dart';
import 'package:dalattrip/constants/app_asset_images.dart';
import 'package:dalattrip/domain/entities/place.dart';
import 'package:dalattrip/models/travel_models.dart';
import 'package:dalattrip/features/explore/screens/place_detail_screen.dart';
import 'package:dalattrip/features/places/widgets/place_image.dart';
import 'package:dalattrip/features/weather/screens/weather_screen.dart';
import 'package:dalattrip/features/weather/models/weather_model.dart';
import 'package:dalattrip/features/weather/services/weather_service.dart';
import 'package:dalattrip/features/chatbot/screens/ai_assistant_screen.dart';
import 'package:dalattrip/features/explore/screens/explore_screen.dart';
import 'package:dalattrip/features/explore/widgets/travel_category_grid.dart';
import 'package:dalattrip/features/plan/screens/create_trip_screen.dart';

/// Screen 1: Trang chủ DaLatTrip / DalatGo
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: CustomScrollView(
        slivers: [
          // App Bar with Brand Logo & Notification
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            title: Row(
              children: [AppAssetImages.logo(height: 36, fit: BoxFit.contain)],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.wb_sunny_outlined,
                  color: AppColors.primary,
                ),
                tooltip: 'Thời tiết Đà Lạt',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WeatherScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.notifications_none,
                  color: AppColors.primary,
                ),
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Greeting Banner (Ảnh mới siêu nét nhà thờ & đồi thông bình minh)
                Container(
                  margin: const EdgeInsets.all(16),
                  height: 175,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AppAssetImages.splashBg(
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -0.3),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.7),
                                Colors.transparent,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Xin chào,',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Bạn muốn khám phá\nĐà Lạt hôm nay?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const CreateTripScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Lên lịch trình ngay ➔',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Live Weather Banner Widget
                const _HomeWeatherWidget(),

                const SizedBox(height: 12),

                // 3. Search Box
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm địa điểm, quán ăn, cafe...',
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13.5,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.primary,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.smart_toy_outlined,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AiAssistantScreen(),
                              ),
                            );
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Category Grids
                TravelCategoryGrid(
                  selectedCategory: null,
                  onCategorySelected: (category) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ExploreScreen(initialCategory: category),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 5. Featured Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Đang hot trên DaLatTrip 🔥',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Xem tất cả >',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Horizontal Carousel — ảnh cố định, chỉ tải khi card xuất hiện.
                SizedBox(
                  height: 190,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: TravelData.samplePlaces.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = TravelData.samplePlaces[index];
                      final domainPlace = Place(
                        id: item.id,
                        name: item.title,
                        categories: [item.category],
                        priceMin: 0,
                        priceMax: 0,
                        visitDurationMinutes: 90,
                        rating: item.rating,
                        indoor: false,
                        imageUrl: item.image,
                      );
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PlaceDetailScreen(place: item),
                            ),
                          );
                        },
                        child: Container(
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PlaceImage(
                                place: domainPlace,
                                width: 150,
                                height: 105,
                                borderRadius: 0,
                                fit: BoxFit.cover,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Color(0xFFFFB300),
                                          size: 13,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${item.rating}',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          item.distance,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact Live Weather Widget for Home Screen
class _HomeWeatherWidget extends StatelessWidget {
  const _HomeWeatherWidget();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeatherData>(
      future: WeatherService().fetchDalatWeather(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? WeatherService.fallbackDalatWeather();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WeatherScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F7F4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  if (data.iconUrl.isNotEmpty)
                    Image.network(
                      data.iconUrl,
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.wb_sunny_rounded,
                        color: Colors.amber,
                        size: 26,
                      ),
                    )
                  else
                    const Icon(
                      Icons.cloud_outlined,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Thời tiết Đà Lạt: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${data.tempC.round()}°C • ${data.conditionText}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Độ ẩm ${data.humidity}% • Gió ${data.windKph} km/h • Cảm giác ${data.feelsLikeC.round()}°C',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
