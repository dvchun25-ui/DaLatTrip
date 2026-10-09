/// Model đại diện cho dữ liệu thời tiết thực tế từ WeatherAPI.com
class WeatherData {
  final String cityName;
  final String country;
  final double tempC;
  final double feelsLikeC;
  final String conditionText;
  final String iconUrl;
  final int humidity;
  final double windKph;
  final double uvIndex;
  final List<ForecastDay> forecastDays;

  const WeatherData({
    required this.cityName,
    required this.country,
    required this.tempC,
    required this.feelsLikeC,
    required this.conditionText,
    required this.iconUrl,
    required this.humidity,
    required this.windKph,
    required this.uvIndex,
    required this.forecastDays,
  });

  /// Normalize icon URL (chuyển //cdn... thành https://cdn...)
  static String normalizeIconUrl(String rawUrl) {
    if (rawUrl.startsWith('//')) {
      return 'https:$rawUrl';
    }
    if (!rawUrl.startsWith('http')) {
      return 'https://$rawUrl';
    }
    return rawUrl;
  }

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? {};
    final current = json['current'] as Map<String, dynamic>? ?? {};
    final condition = current['condition'] as Map<String, dynamic>? ?? {};
    final forecastObj = json['forecast'] as Map<String, dynamic>? ?? {};
    final forecastListRaw = forecastObj['forecastday'] as List<dynamic>? ?? [];

    final forecastDays = forecastListRaw
        .map((e) => ForecastDay.fromJson(e as Map<String, dynamic>))
        .toList();

    return WeatherData(
      cityName: (location['name'] as String?) ?? 'Đà Lạt',
      country: (location['country'] as String?) ?? 'Việt Nam',
      tempC: (current['temp_c'] as num?)?.toDouble() ?? 20.0,
      feelsLikeC: (current['feelslike_c'] as num?)?.toDouble() ?? 20.0,
      conditionText: (condition['text'] as String?) ?? 'Nhiều mây',
      iconUrl: normalizeIconUrl((condition['icon'] as String?) ?? ''),
      humidity: (current['humidity'] as num?)?.toInt() ?? 80,
      windKph: (current['wind_kph'] as num?)?.toDouble() ?? 5.0,
      uvIndex: (current['uv'] as num?)?.toDouble() ?? 5.0,
      forecastDays: forecastDays,
    );
  }

  /// Tìm ngày có nguy cơ mưa trong dự báo
  ForecastDay? get rainyDayWarning {
    for (final day in forecastDays) {
      if (day.willItRain || day.chanceOfRain >= 50) {
        return day;
      }
    }
    return null;
  }
}

/// Dự báo thời tiết theo ngày
class ForecastDay {
  final String date;
  final double maxTempC;
  final double minTempC;
  final double avgTempC;
  final String conditionText;
  final String iconUrl;
  final int chanceOfRain;
  final bool willItRain;

  const ForecastDay({
    required this.date,
    required this.maxTempC,
    required this.minTempC,
    required this.avgTempC,
    required this.conditionText,
    required this.iconUrl,
    required this.chanceOfRain,
    required this.willItRain,
  });

  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    final dayObj = json['day'] as Map<String, dynamic>? ?? {};
    final condition = dayObj['condition'] as Map<String, dynamic>? ?? {};

    return ForecastDay(
      date: (json['date'] as String?) ?? '',
      maxTempC: (dayObj['maxtemp_c'] as num?)?.toDouble() ?? 22.0,
      minTempC: (dayObj['mintemp_c'] as num?)?.toDouble() ?? 16.0,
      avgTempC: (dayObj['avgtemp_c'] as num?)?.toDouble() ?? 18.0,
      conditionText: (condition['text'] as String?) ?? 'Có mây',
      iconUrl: WeatherData.normalizeIconUrl((condition['icon'] as String?) ?? ''),
      chanceOfRain: (dayObj['daily_chance_of_rain'] as num?)?.toInt() ?? 0,
      willItRain: ((dayObj['daily_will_it_rain'] as num?)?.toInt() ?? 0) == 1,
    );
  }

  /// Format nhãn hiển thị ngày (ví dụ: "Hôm nay", "Ngày mai", hoặc "07/10")
  String displayDayLabel(int index) {
    if (index == 0) return 'Hôm nay';
    if (index == 1) return 'Ngày mai';
    if (index == 2) return 'Ngày kia';

    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}';
      }
    } catch (_) {}
    return date;
  }
}
