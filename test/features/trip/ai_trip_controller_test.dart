import 'package:dalattrip/domain/entities/ai_trip_parse_result.dart';
import 'package:dalattrip/domain/entities/trip_request.dart';
import 'package:dalattrip/domain/repositories/ai_trip_repository.dart';
import 'package:dalattrip/features/trip/controllers/ai_trip_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserves collected data across follow-up answers', () async {
    final repository = _FakeRepository();
    final controller = AiTripController(repository: repository);

    await controller.submitMessage(
      'Đi Đà Lạt 3 ngày với người yêu, thích thiên nhiên và cà phê.',
    );
    expect(controller.isReady, isFalse);
    expect(controller.result?.missingFields, [
      'totalBudget',
      'transport',
      'pace',
    ]);

    await controller.submitMessage(
      'Ngân sách 5 triệu, đi xe máy và muốn thư giãn.',
    );

    expect(repository.secondPreviousData?['days'], 3);
    expect(repository.secondPreviousData?['people'], 2);
    expect(controller.isReady, isTrue);
    expect(controller.tripRequest?.isValid, isTrue);
  });
}

class _FakeRepository implements AiTripRepository {
  var calls = 0;
  Map<String, dynamic>? secondPreviousData;

  @override
  Future<AiTripParseResult> parseTripRequest({
    required String message,
    Map<String, dynamic>? previousData,
  }) async {
    calls++;
    if (calls == 1) {
      return const AiTripParseResult(
        status: AiTripParseStatus.needsMoreInfo,
        collectedData: {
          'days': 3,
          'people': 2,
          'interests': ['nature', 'cafe'],
        },
        missingFields: ['totalBudget', 'transport', 'pace'],
        questions: ['Ngân sách?', 'Phương tiện?', 'Nhịp độ?'],
      );
    }
    secondPreviousData = previousData;
    return const AiTripParseResult(
      status: AiTripParseStatus.ready,
      tripRequest: TripRequest(
        days: 3,
        people: 2,
        totalBudget: 5000000,
        interests: ['nature', 'cafe'],
        transport: 'motorbike',
        pace: 'relaxed',
      ),
      collectedData: {
        'days': 3,
        'people': 2,
        'totalBudget': 5000000,
        'interests': ['nature', 'cafe'],
        'transport': 'motorbike',
        'pace': 'relaxed',
      },
    );
  }
}

// ignore_for_file: deprecated_member_use_from_same_package
