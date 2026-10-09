import 'package:dalattrip/domain/services/clarification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClarificationService (TASK 9)', () {
    late ClarificationService service;

    setUp(() {
      service = ClarificationService();
    });

    test(
      'returns exact required questions when totalBudget, transport, pace are missing',
      () {
        final questions = service.buildQuestions(
          missingFields: ['totalBudget', 'transport', 'pace'],
          collectedData: {
            'days': 3,
            'people': 2,
            'interests': ['nature', 'cafe'],
          },
        );

        expect(questions.length, 3);

        expect(questions[0].field, 'totalBudget');
        expect(questions[0].text, 'Ngân sách tổng khoảng bao nhiêu?');
        expect(questions[0].quickOptions.isNotEmpty, isTrue);

        expect(questions[1].field, 'transport');
        expect(questions[1].text, 'Bạn di chuyển bằng phương tiện nào?');
        expect(questions[1].quickOptions.isNotEmpty, isTrue);

        expect(questions[2].field, 'pace');
        expect(
          questions[2].text,
          'Bạn muốn lịch trình thư giãn hay khám phá nhiều?',
        );
        expect(questions[2].quickOptions.isNotEmpty, isTrue);
      },
    );

    test(
      'does not ask questions for fields already present in collectedData',
      () {
        final questions = service.buildQuestions(
          missingFields: ['totalBudget', 'transport', 'pace'],
          collectedData: {'totalBudget': 5000000, 'transport': 'motorbike'},
        );

        expect(questions.length, 1);
        expect(questions.first.field, 'pace');
        expect(
          questions.first.text,
          'Bạn muốn lịch trình thư giãn hay khám phá nhiều?',
        );
      },
    );

    test('limits maximum questions to 3 per turn', () {
      final questions = service.buildQuestions(
        missingFields: [
          'days',
          'people',
          'interests',
          'totalBudget',
          'transport',
          'pace',
        ],
        collectedData: {},
      );

      expect(questions.length, 3);
      expect(questions.map((q) => q.field).toList(), [
        'days',
        'people',
        'interests',
      ]);
    });

    test('provides quick options for quick reply selection', () {
      final questions = service.buildQuestions(
        missingFields: ['transport'],
        collectedData: {},
      );

      expect(questions.length, 1);
      final quickOptions = questions.first.quickOptions;
      expect(
        quickOptions.map((o) => o.label),
        containsAll(['Xe máy', 'Ô tô', 'Taxi', 'Đi bộ']),
      );
    });
  });
}
