class TripRequest {
  static const Set<String> supportedTransports = {
    'motorbike',
    'car',
    'taxi',
    'walking',
  };

  static const Set<String> supportedPaces = {'relaxed', 'balanced', 'packed'};

  final int days;
  final int people;
  final int totalBudget;
  final List<String> interests;
  final String transport;
  final String pace;
  final String? startLocation;
  final List<String> specialRequirements;

  const TripRequest({
    required this.days,
    required this.people,
    required this.totalBudget,
    required this.interests,
    required this.transport,
    required this.pace,
    this.startLocation,
    this.specialRequirements = const [],
  });

  bool get isValid {
    return days >= 2 &&
        days <= 5 &&
        people >= 1 &&
        totalBudget > 0 &&
        interests.isNotEmpty &&
        supportedTransports.contains(transport) &&
        supportedPaces.contains(pace);
  }

  TripRequest copyWith({
    int? days,
    int? people,
    int? totalBudget,
    List<String>? interests,
    String? transport,
    String? pace,
    String? startLocation,
    List<String>? specialRequirements,
  }) {
    return TripRequest(
      days: days ?? this.days,
      people: people ?? this.people,
      totalBudget: totalBudget ?? this.totalBudget,
      interests: interests ?? this.interests,
      transport: transport ?? this.transport,
      pace: pace ?? this.pace,
      startLocation: startLocation ?? this.startLocation,
      specialRequirements: specialRequirements ?? this.specialRequirements,
    );
  }
}
