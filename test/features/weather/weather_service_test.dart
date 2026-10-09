import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dalattrip/features/weather/models/weather_model.dart';
import 'package:dalattrip/features/weather/services/weather_service.dart';

void main() {
  group('WeatherModel Tests', () {
    const mockJson = {
      "location": {
        "name": "Da Lat",
        "region": "",
        "country": "Vietnam",
        "lat": 11.9333,
        "lon": 108.4167,
        "tz_id": "Asia/Ho_Chi_Minh",
        "localtime": "2026-10-06 11:54"
      },
      "current": {
        "temp_c": 26.4,
        "feelslike_c": 27.0,
        "condition": {
          "text": "Mưa phùn nhẹ",
          "icon": "//cdn.weatherapi.com/weather/64x64/day/266.png"
        },
        "humidity": 50,
        "wind_kph": 4.7,
        "uv": 10.5
      },
      "forecast": {
        "forecastday": [
          {
            "date": "2026-10-06",
            "day": {
              "maxtemp_c": 26.4,
              "mintemp_c": 15.5,
              "avgtemp_c": 18.4,
              "daily_chance_of_rain": 36,
              "daily_will_it_rain": 0,
              "condition": {
                "text": "Mưa phùn nhẹ",
                "icon": "//cdn.weatherapi.com/weather/64x64/day/266.png"
              }
            }
          },
          {
            "date": "2026-10-07",
            "day": {
              "maxtemp_c": 21.4,
              "mintemp_c": 15.4,
              "avgtemp_c": 17.7,
              "daily_chance_of_rain": 93,
              "daily_will_it_rain": 1,
              "condition": {
                "text": "Mưa vừa",
                "icon": "//cdn.weatherapi.com/weather/64x64/day/302.png"
              }
            }
          }
        ]
      }
    };

    test('WeatherData.fromJson parses JSON correctly', () {
      final weather = WeatherData.fromJson(mockJson);

      expect(weather.cityName, 'Da Lat');
      expect(weather.country, 'Vietnam');
      expect(weather.tempC, 26.4);
      expect(weather.feelsLikeC, 27.0);
      expect(weather.conditionText, 'Mưa phùn nhẹ');
      expect(weather.iconUrl, 'https://cdn.weatherapi.com/weather/64x64/day/266.png');
      expect(weather.humidity, 50);
      expect(weather.windKph, 4.7);
      expect(weather.uvIndex, 10.5);
      expect(weather.forecastDays.length, 2);
    });

    test('ForecastDay parses day items & displays correct labels', () {
      final weather = WeatherData.fromJson(mockJson);
      final day1 = weather.forecastDays[0];
      final day2 = weather.forecastDays[1];

      expect(day1.displayDayLabel(0), 'Hôm nay');
      expect(day2.displayDayLabel(1), 'Ngày mai');
      expect(day2.chanceOfRain, 93);
      expect(day2.willItRain, true);
    });

    test('rainyDayWarning identifies rainy day correctly', () {
      final weather = WeatherData.fromJson(mockJson);
      final warning = weather.rainyDayWarning;

      expect(warning, isNotNull);
      expect(warning!.date, '2026-10-07');
      expect(warning.chanceOfRain, 93);
    });

    test('normalizeIconUrl converts protocol-relative URL to https', () {
      expect(
        WeatherData.normalizeIconUrl('//cdn.weatherapi.com/test.png'),
        'https://cdn.weatherapi.com/test.png',
      );
      expect(
        WeatherData.normalizeIconUrl('https://cdn.weatherapi.com/test.png'),
        'https://cdn.weatherapi.com/test.png',
      );
    });
  });

  group('WeatherService Tests', () {
    test('fetchDalatWeather parses API response on 200 OK', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('api.weatherapi.com'));
        expect(request.url.toString(), contains('key=8db1b55cd17b43eba4f45254260610'));

        const responseJson = '''
        {
          "location": {"name": "Da Lat", "country": "Vietnam"},
          "current": {
            "temp_c": 22.0,
            "feelslike_c": 22.5,
            "condition": {"text": "Nắng nhẹ", "icon": "//cdn.weatherapi.com/day.png"},
            "humidity": 75,
            "wind_kph": 5.0,
            "uv": 6.0
          },
          "forecast": {"forecastday": []}
        }
        ''';
        return http.Response(
          responseJson,
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = WeatherService(client: mockClient);
      final weather = await service.fetchDalatWeather();

      expect(weather.cityName, 'Da Lat');
      expect(weather.tempC, 22.0);
      expect(weather.conditionText, 'Nắng nhẹ');
    });

    test('fetchDalatWeather returns fallback weather on API failure', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final service = WeatherService(client: mockClient);
      final weather = await service.fetchDalatWeather();

      expect(weather.cityName, 'Đà Lạt');
      expect(weather.forecastDays, isNotEmpty);
    });
  });
}
