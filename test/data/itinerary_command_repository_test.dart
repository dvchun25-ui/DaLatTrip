import 'package:dalattrip/core/network/api_client.dart';
import 'package:dalattrip/data/repositories/itinerary_command_repository_impl.dart';
import 'package:dalattrip/domain/entities/itinerary_command.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('uses local command parser when backend cannot connect', () async {
    final httpClient = MockClient((_) async {
      throw http.ClientException('backend offline');
    });
    final repository = ItineraryCommandRepositoryImpl(
      apiClient: ApiClient(
        baseUrl: 'http://localhost:8000/api/v1',
        httpClient: httpClient,
      ),
    );

    final command = await repository.parseCommand(
      message: 'Tôi muốn nghỉ ngơi ngày 1 bắt đầu từ 10g',
      selectedDay: 1,
      places: const [],
    );

    expect(command.action, ItineraryCommandAction.adjustDayStart);
    expect(command.dayNumber, 1);
    expect(command.startMinute, 600);
    expect(command.usedLocalFallback, isTrue);
  });

  test('does not require a place for commands unrelated to a place', () async {
    final httpClient = MockClient((_) async {
      throw http.ClientException('backend offline');
    });
    final repository = ItineraryCommandRepositoryImpl(
      apiClient: ApiClient(httpClient: httpClient),
    );

    final command = await repository.parseCommand(
      message: 'Giảm ngân sách xuống 4 triệu',
      selectedPlaceId: null,
      selectedDay: 1,
      places: const [],
    );

    expect(command.action, ItineraryCommandAction.updateBudget);
    expect(command.totalBudget, 4000000);
  });
}
