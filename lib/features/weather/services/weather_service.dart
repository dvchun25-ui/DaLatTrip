import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  static const String apiKey = '8db1b55cd17b43eba4f45254260610';
  static const String baseUrl = 'https://api.weatherapi.com/v1';

  final http.Client _client;

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  /// Tải thông tin thời tiết Đà Lạt (bao gồm dự báo 3 ngày)
  Future<WeatherData> fetchDalatWeather({String location = 'Da Lat'}) async {
    final url = Uri.parse(
      '$baseUrl/forecast.json?key=$apiKey&q=${Uri.encodeComponent(location)}&days=3&lang=vi',
    );

    try {
      final response = await _client.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return WeatherData.fromJson(decoded);
      } else {
        throw Exception('Không thể tải thời tiết (Mã lỗi: ${response.statusCode})');
      }
    } on Exception catch (_) {
      // Dữ liệu dự phòng an toàn khi mất kết nối
      return fallbackDalatWeather();
    }
  }

  /// Dữ liệu thời tiết dự phòng Đà Lạt
  static WeatherData fallbackDalatWeather() {
    return const WeatherData(
      cityName: 'Đà Lạt',
      country: 'Việt Nam',
      tempC: 19.5,
      feelsLikeC: 20.0,
      conditionText: 'Nhiều mây & sương mù',
      iconUrl: 'https://cdn.weatherapi.com/weather/64x64/day/116.png',
      humidity: 85,
      windKph: 6.2,
      uvIndex: 4.0,
      forecastDays: [
        ForecastDay(
          date: 'Hôm nay',
          maxTempC: 22.0,
          minTempC: 15.5,
          avgTempC: 18.5,
          conditionText: 'Sương mù & Nắng nhẹ',
          iconUrl: 'https://cdn.weatherapi.com/weather/64x64/day/116.png',
          chanceOfRain: 25,
          willItRain: false,
        ),
        ForecastDay(
          date: 'Ngày mai',
          maxTempC: 20.5,
          minTempC: 16.0,
          avgTempC: 18.0,
          conditionText: 'Mưa rào nhẹ rải rác',
          iconUrl: 'https://cdn.weatherapi.com/weather/64x64/day/353.png',
          chanceOfRain: 70,
          willItRain: true,
        ),
        ForecastDay(
          date: 'Ngày kia',
          maxTempC: 21.0,
          minTempC: 15.0,
          avgTempC: 18.2,
          conditionText: 'Trời âm u & Mây rải rác',
          iconUrl: 'https://cdn.weatherapi.com/weather/64x64/day/119.png',
          chanceOfRain: 40,
          willItRain: false,
        ),
      ],
    );
  }
}
