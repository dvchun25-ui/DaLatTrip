import 'package:flutter/foundation.dart';

import '../../../domain/entities/trip_request.dart';

class CreateTripController extends ChangeNotifier {
  int _days = 3;
  int _people = 2;
  int _totalBudget = 5000000;
  String _transport = 'motorbike';
  String _pace = 'balanced';
  String? _startLocation;
  List<String> _interests = const [];
  List<String> _specialRequirements = const [];

  int get days => _days;
  int get people => _people;
  int get totalBudget => _totalBudget;
  String get transport => _transport;
  String get pace => _pace;
  String? get startLocation => _startLocation;
  List<String> get interests => List.unmodifiable(_interests);
  List<String> get specialRequirements =>
      List.unmodifiable(_specialRequirements);

  void setDays(int value) {
    _days = value;
    notifyListeners();
  }

  void setPeople(int value) {
    _people = value;
    notifyListeners();
  }

  void setTotalBudget(int value) {
    _totalBudget = value;
    notifyListeners();
  }

  void setTransport(String value) {
    _transport = value;
    notifyListeners();
  }

  void setPace(String value) {
    _pace = value;
    notifyListeners();
  }

  void setStartLocation(String? value) {
    final normalized = value?.trim();
    _startLocation = normalized == null || normalized.isEmpty
        ? null
        : normalized;
    notifyListeners();
  }

  void setInterests(Iterable<String> values) {
    _interests = values
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
    notifyListeners();
  }

  void setSpecialRequirements(Iterable<String> values) {
    _specialRequirements = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    notifyListeners();
  }

  String? validateTripDetails() {
    if (_days < 2 || _days > 5) return 'Số ngày phải từ 2 đến 5.';
    if (_people < 1) return 'Số người phải lớn hơn hoặc bằng 1.';
    if (_totalBudget <= 0) return 'Ngân sách phải lớn hơn 0.';
    if (!TripRequest.supportedTransports.contains(_transport)) {
      return 'Phương tiện không được hỗ trợ.';
    }
    if (!TripRequest.supportedPaces.contains(_pace)) {
      return 'Nhịp độ không được hỗ trợ.';
    }
    return null;
  }

  String? validate() {
    final detailError = validateTripDetails();
    if (detailError != null) return detailError;
    if (_interests.isEmpty) return 'Vui lòng chọn ít nhất một sở thích.';
    return null;
  }

  TripRequest createTripRequest() {
    final error = validate();
    if (error != null) throw StateError(error);
    return TripRequest(
      days: _days,
      people: _people,
      totalBudget: _totalBudget,
      interests: List.unmodifiable(_interests),
      transport: _transport,
      pace: _pace,
      startLocation: _startLocation,
      specialRequirements: List.unmodifiable(_specialRequirements),
    );
  }
}
