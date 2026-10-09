class ClarificationOption {
  final String label;
  final String answer;

  const ClarificationOption({required this.label, required this.answer});
}

class ClarificationQuestion {
  final String field;
  final String text;
  final List<ClarificationOption> quickOptions;

  const ClarificationQuestion({
    required this.field,
    required this.text,
    this.quickOptions = const [],
  });
}
