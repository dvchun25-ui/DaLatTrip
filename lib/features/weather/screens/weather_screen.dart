import 'package:flutter/material.dart';
import 'package:dalattrip/constants/app_colors.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

/// Screen 9: Thời tiết Đà Lạt thời gian thực & Gợi ý lịch trình
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  late Future<WeatherData> _weatherFuture;

  @override
  void initState() {
    super.initState();
    _refreshWeather();
  }

  void _refreshWeather() {
    setState(() {
      _weatherFuture = _weatherService.fetchDalatWeather();
    });
  }

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
          'Thời tiết & Gợi ý Đà Lạt',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'Làm mới thời tiết',
            onPressed: _refreshWeather,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshWeather();
          await _weatherFuture;
        },
        color: AppColors.primary,
        child: FutureBuilder<WeatherData>(
          future: _weatherFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final data = snapshot.data ?? WeatherService.fallbackDalatWeather();

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Current Live Weather Hero Card
                  _buildLiveWeatherHeroCard(data),

                  const SizedBox(height: 24),

                  // 2. Weather Parameters Details Grid
                  _buildWeatherDetailsGrid(data),

                  const SizedBox(height: 24),

                  // 3. Header Dự báo 3 ngày
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Dự báo 3 ngày tại ${data.cityName}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 3 Days Forecast Cards
                  if (data.forecastDays.isNotEmpty)
                    Row(
                      children: data.forecastDays.asMap().entries.map((entry) {
                        final index = entry.key;
                        final day = entry.value;
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                              right: index < data.forecastDays.length - 1 ? 10 : 0,
                            ),
                            child: _buildWeatherDayCard(day, index),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 24),

                  // 4. Weather Warning Card (Tự động phát hiện ngày có mưa)
                  _buildRainWarningCard(data),

                  const SizedBox(height: 24),

                  // 5. Gợi ý hoạt động ngày mưa / thời tiết xấu
                  const Text(
                    'Gợi ý hoạt động phù hợp',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _buildActivityChip(
                        'Tham quan\nbảo tàng',
                        Icons.museum_outlined,
                      ),
                      const SizedBox(width: 10),
                      _buildActivityChip(
                        'Cafe view\nđẹp',
                        Icons.local_cafe_outlined,
                      ),
                      const SizedBox(width: 10),
                      _buildActivityChip(
                        'Mua sắm\nđặc sản',
                        Icons.shopping_basket_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Live Weather Hero Card
  Widget _buildLiveWeatherHeroCard(WeatherData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white70, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${data.cityName}, ${data.country}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Trực tiếp',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data.tempC.round()}°C',
                    style: const TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.conditionText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cảm giác như ${data.feelsLikeC.round()}°C',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              if (data.iconUrl.isNotEmpty)
                Image.network(
                  data.iconUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.wb_sunny_rounded,
                    size: 64,
                    color: Colors.amber,
                  ),
                )
              else
                const Icon(
                  Icons.cloud_outlined,
                  size: 64,
                  color: Colors.white,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Grid thông số độ ẩm, gió, UV
  Widget _buildWeatherDetailsGrid(WeatherData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDetailItem(
            Icons.water_drop_outlined,
            '${data.humidity}%',
            'Độ ẩm',
          ),
          Container(height: 30, width: 1, color: AppColors.divider),
          _buildDetailItem(
            Icons.air_rounded,
            '${data.windKph} km/h',
            'Sức gió',
          ),
          Container(height: 30, width: 1, color: AppColors.divider),
          _buildDetailItem(
            Icons.wb_sunny_outlined,
            '${data.uvIndex}',
            'Chỉ số UV',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Card dự báo từng ngày
  Widget _buildWeatherDayCard(ForecastDay day, int index) {
    final bool isRain = day.willItRain || day.chanceOfRain >= 50;

    return Container(
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
          Text(
            day.displayDayLabel(index),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (day.iconUrl.isNotEmpty)
            Image.network(
              day.iconUrl,
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                isRain ? Icons.grain_outlined : Icons.wb_sunny_outlined,
                color: isRain ? const Color(0xFF1E88E5) : const Color(0xFFFFA000),
                size: 28,
              ),
            )
          else
            Icon(
              isRain ? Icons.grain_outlined : Icons.wb_sunny_outlined,
              color: isRain ? const Color(0xFF1E88E5) : const Color(0xFFFFA000),
              size: 28,
            ),
          const SizedBox(height: 8),
          Text(
            '${day.maxTempC.round()}° / ${day.minTempC.round()}°',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            day.conditionText,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: isRain ? const Color(0xFFD32F2F) : AppColors.textSecondary,
            ),
          ),
          if (day.chanceOfRain > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.water_drop,
                  size: 10,
                  color: Color(0xFF1976D2),
                ),
                const SizedBox(width: 2),
                Text(
                  '${day.chanceOfRain}%',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Cảnh báo mưa tự động
  Widget _buildRainWarningCard(WeatherData data) {
    final warningDay = data.rainyDayWarning;
    final bool hasRain = warningDay != null;

    final title = hasRain
        ? 'Dự báo có mưa (${warningDay.chanceOfRain}% khả năng)'
        : 'Thời tiết Đà Lạt thuận lợi';
    final description = hasRain
        ? 'Dự báo có thể có mưa vào ngày ${warningDay.date}. DaLatTrip gợi ý bạn lên kế hoạch cho các hoạt động trong nhà hoặc chuẩn bị ô/áo mưa.'
        : 'Thời tiết Đà Lạt khá đẹp và lý tưởng cho các hoạt động tham quan ngoài trời cũng như săn mây!';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasRain ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasRain ? const Color(0xFFFFCDD2) : const Color(0xFFC8E6C9),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasRain ? Icons.umbrella_outlined : Icons.wb_sunny_outlined,
            color: hasRain ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: hasRain
                        ? const Color(0xFFD32F2F)
                        : const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
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
