import 'package:dalattrip/data/models/ai_trip_parse_result_model.dart';
import 'package:dalattrip/domain/entities/ai_trip_parse_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses needs_more_info with collected data and questions', () {
    final result = AiTripParseResultModel.fromJson({
      'status': 'needs_more_info',
      'tripRequest': null,
      'collectedData': {
        'days': 3,
        'people': 2,
        'totalBudget': null,
        'interests': ['nature', 'cafe'],
        'transport': null,
        'pace': null,
      },
      'missingFields': ['totalBudget', 'transport', 'pace'],
      'questions': ['Ngân sách?', 'Phương tiện?', 'Nhịp độ?'],
      'message': 'Cần thêm thông tin.',
    });

    expect(result.status, AiTripParseStatus.needsMoreInfo);
    expect(result.tripRequest, isNull);
    expect(result.collectedData['days'], 3);
    expect(result.collectedData['totalBudget'], isNull);
    expect(result.collectedData['transport'], isNull);
    expect(result.collectedData['pace'], isNull);
    expect(result.missingFields, ['totalBudget', 'transport', 'pace']);
    expect(result.questions, hasLength(3));
  });

  test('parses ready response into a valid TripRequest', () {
    final result = AiTripParseResultModel.fromJson({
      'status': 'ready',
      'tripRequest': {
        'days': 3,
        'people': 2,
        'totalBudget': 5000000,
        'interests': ['nature', 'cafe'],
        'transport': 'motorbike',
        'pace': 'relaxed',
        'startLocation': null,
        'specialRequirements': <String>[],
      },
      'collectedData': {
        'days': 3,
        'people': 2,
        'totalBudget': 5000000,
        'interests': ['nature', 'cafe'],
        'transport': 'motorbike',
        'pace': 'relaxed',
      },
      'missingFields': <String>[],
      'questions': <String>[],
      'message': 'Đã đủ thông tin.',
    });

    expect(result.status, AiTripParseStatus.ready);
    expect(result.tripRequest?.isValid, isTrue);
    expect(result.tripRequest?.days, 3);
    expect(result.tripRequest?.totalBudget, 5000000);
    expect(result.tripRequest?.interests, ['nature', 'cafe']);
  });
}
