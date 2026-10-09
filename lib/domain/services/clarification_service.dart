import '../entities/clarification_question.dart';

class ClarificationService {
  static const int maximumQuestionsPerTurn = 3;

  static const Map<String, ClarificationQuestion> _questions = {
    'days': ClarificationQuestion(
      field: 'days',
      text: 'Bạn muốn đi Đà Lạt trong bao nhiêu ngày?',
      quickOptions: [
        ClarificationOption(label: '2 ngày', answer: 'Tôi đi 2 ngày'),
        ClarificationOption(label: '3 ngày', answer: 'Tôi đi 3 ngày'),
        ClarificationOption(label: '4 ngày', answer: 'Tôi đi 4 ngày'),
      ],
    ),
    'people': ClarificationQuestion(
      field: 'people',
      text: 'Chuyến đi có bao nhiêu người?',
      quickOptions: [
        ClarificationOption(label: '1 người', answer: 'Tôi đi 1 người'),
        ClarificationOption(label: '2 người', answer: 'Tôi đi 2 người'),
        ClarificationOption(label: '4 người', answer: 'Tôi đi 4 người'),
      ],
    ),
    'interests': ClarificationQuestion(
      field: 'interests',
      text: 'Bạn thích loại trải nghiệm nào?',
      quickOptions: [
        ClarificationOption(
          label: 'Thiên nhiên',
          answer: 'Tôi thích thiên nhiên',
        ),
        ClarificationOption(label: 'Cà phê', answer: 'Tôi thích cafe'),
        ClarificationOption(label: 'Ẩm thực', answer: 'Tôi thích ăn uống'),
      ],
    ),
    'totalBudget': ClarificationQuestion(
      field: 'totalBudget',
      text: 'Ngân sách tổng khoảng bao nhiêu?',
      quickOptions: [
        ClarificationOption(label: '3 triệu', answer: 'Ngân sách 3 triệu'),
        ClarificationOption(label: '5 triệu', answer: 'Ngân sách 5 triệu'),
        ClarificationOption(label: '8 triệu', answer: 'Ngân sách 8 triệu'),
      ],
    ),
    'transport': ClarificationQuestion(
      field: 'transport',
      text: 'Bạn di chuyển bằng phương tiện nào?',
      quickOptions: [
        ClarificationOption(label: 'Xe máy', answer: 'Tôi đi xe máy'),
        ClarificationOption(label: 'Ô tô', answer: 'Tôi đi ô tô'),
        ClarificationOption(label: 'Taxi', answer: 'Tôi đi taxi'),
        ClarificationOption(label: 'Đi bộ', answer: 'Tôi đi bộ'),
      ],
    ),
    'pace': ClarificationQuestion(
      field: 'pace',
      text: 'Bạn muốn lịch trình thư giãn hay khám phá nhiều?',
      quickOptions: [
        ClarificationOption(label: 'Thư giãn', answer: 'Lịch trình thư giãn'),
        ClarificationOption(label: 'Cân bằng', answer: 'Lịch trình cân bằng'),
        ClarificationOption(
          label: 'Khám phá nhiều',
          answer: 'Tôi muốn đi nhiều địa điểm',
        ),
      ],
    ),
  };

  List<ClarificationQuestion> buildQuestions({
    required List<String> missingFields,
    required Map<String, dynamic> collectedData,
  }) {
    final result = <ClarificationQuestion>[];
    for (final field in missingFields) {
      if (_hasValue(collectedData[field])) continue;
      final question = _questions[field];
      if (question != null) result.add(question);
      if (result.length == maximumQuestionsPerTurn) break;
    }
    return List.unmodifiable(result);
  }

  bool _hasValue(Object? value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Iterable) return value.isNotEmpty;
    return true;
  }
}
