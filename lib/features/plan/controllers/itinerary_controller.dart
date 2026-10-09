import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../data/datasources/local_place_data_source.dart';
import '../../../data/repositories/itinerary_command_repository_impl.dart';
import '../../../data/repositories/local_itinerary_storage_repository.dart';
import '../../../data/repositories/place_repository_impl.dart';
import '../../../domain/builders/itinerary_builder.dart';
import '../../../domain/engines/recommendation_engine.dart';
import '../../../domain/entities/generated_itinerary.dart';
import '../../../domain/entities/itinerary_command.dart';
import '../../../domain/entities/scored_place.dart';
import '../../../domain/entities/trip_request.dart';
import '../../../domain/repositories/itinerary_command_repository.dart';
import '../../../domain/repositories/itinerary_storage_repository.dart';
import '../../../domain/repositories/place_repository.dart';

class ItineraryController extends ChangeNotifier {
  final PlaceRepository _placeRepository;
  final RecommendationEngine _recommendationEngine;
  final ItineraryBuilder _itineraryBuilder;
  final ItineraryStorageRepository _storageRepository;
  final ItineraryCommandRepository _commandRepository;
  final Set<String> _regenerationExcludedIds = {};
  final Set<String> _commandExcludedIds = {};
  final Map<int, String> _dayPaces = {};
  final Map<int, int> _dayStartMinutes = {};
  final Set<int> _indoorOnlyDays = {};

  ItineraryController({
    PlaceRepository? placeRepository,
    RecommendationEngine? recommendationEngine,
    ItineraryBuilder? itineraryBuilder,
    ItineraryStorageRepository? storageRepository,
    ItineraryCommandRepository? commandRepository,
    TripRequest? initialRequest,
    GeneratedItinerary? initialItinerary,
  }) : _placeRepository =
           placeRepository ??
           PlaceRepositoryImpl(localDataSource: LocalPlaceDataSource()),
       _recommendationEngine = recommendationEngine ?? RecommendationEngine(),
       _itineraryBuilder = itineraryBuilder ?? ItineraryBuilder(),
       _storageRepository =
           storageRepository ?? LocalItineraryStorageRepository(),
       _commandRepository =
           commandRepository ??
           ItineraryCommandRepositoryImpl(apiClient: ApiClient()),
       currentRequest = initialRequest,
       itinerary = initialItinerary;

  bool isLoading = false;
  bool isSaving = false;
  bool isSaved = false;
  bool isApplyingCommand = false;
  String? errorMessage;
  String? commandErrorMessage;
  String? saveErrorMessage;
  String? lastCommandMessage;
  TripRequest? currentRequest;
  GeneratedItinerary? itinerary;

  Future<void> generate(TripRequest request) async {
    currentRequest = request;
    _regenerationExcludedIds.clear();
    _commandExcludedIds.clear();
    _dayPaces.clear();
    _dayStartMinutes.clear();
    _indoorOnlyDays.clear();
    await _build(request);
  }

  Future<void> regenerate([TripRequest? request]) async {
    final effectiveRequest = request ?? currentRequest;
    if (effectiveRequest == null) return;
    currentRequest = effectiveRequest;
    final currentPlaceIds = itinerary?.days
        .expand((day) => day.placeItems)
        .map((item) => item.place?.id)
        .whereType<String>();
    if (currentPlaceIds != null) {
      _regenerationExcludedIds.addAll(currentPlaceIds);
    }
    await _build(effectiveRequest);
  }

  Future<void> replacePlace(TripRequest request, String placeId) async {
    currentRequest = request;
    _commandExcludedIds.add(placeId);
    await _build(request);
  }

  Future<void> applyCommand(
    String message, {
    String? selectedPlaceId,
    int? selectedDay,
  }) async {
    final request = currentRequest;
    final generated = itinerary;
    if (request == null || generated == null || isApplyingCommand) return;

    isApplyingCommand = true;
    commandErrorMessage = null;
    lastCommandMessage = null;
    notifyListeners();
    try {
      final contexts = generated.days
          .expand(
            (day) => day.placeItems.map(
              (item) => ItineraryCommandPlaceContext(
                id: item.place!.id,
                name: item.place!.name,
                dayNumber: day.dayNumber,
                indoor: item.place!.indoor,
              ),
            ),
          )
          .toList(growable: false);
      final command = await _commandRepository.parseCommand(
        message: message,
        selectedPlaceId: selectedPlaceId,
        selectedDay: selectedDay,
        places: contexts,
      );
      _applyStructuredCommand(command, selectedDay: selectedDay);
      await _build(currentRequest!);
      if (errorMessage == null) lastCommandMessage = _successMessage(command);
    } catch (error) {
      commandErrorMessage = 'Không thể áp dụng lệnh: $error';
    } finally {
      isApplyingCommand = false;
      notifyListeners();
    }
  }

  void _applyStructuredCommand(ItineraryCommand command, {int? selectedDay}) {
    switch (command.action) {
      case ItineraryCommandAction.removePlace:
        final placeId = command.placeId;
        if (placeId == null) throw StateError('Lệnh thiếu placeId.');
        _commandExcludedIds.add(placeId);
        break;
      case ItineraryCommandAction.addCategory:
        final category = command.category;
        if (category == null) throw StateError('Lệnh thiếu category.');
        currentRequest = currentRequest!.copyWith(
          interests: List.unmodifiable({
            ...currentRequest!.interests,
            category,
          }),
        );
        break;
      case ItineraryCommandAction.adjustDayPace:
        final day = command.dayNumber ?? selectedDay;
        final pace = command.pace;
        if (day == null || pace == null) {
          throw StateError('Lệnh thiếu ngày hoặc nhịp độ.');
        }
        _dayPaces[day] = pace;
        break;
      case ItineraryCommandAction.adjustDayStart:
        final day = command.dayNumber ?? selectedDay;
        final startMinute = command.startMinute;
        if (day == null || startMinute == null) {
          throw StateError('Lệnh thiếu ngày hoặc giờ bắt đầu.');
        }
        if (day < 1 || day > currentRequest!.days) {
          throw StateError('Ngày cần sửa không tồn tại trong chuyến đi.');
        }
        _dayStartMinutes[day] = startMinute;
        break;
      case ItineraryCommandAction.updateBudget:
        final budget = command.totalBudget;
        if (budget == null || budget <= 0) {
          throw StateError('Lệnh thiếu ngân sách hợp lệ.');
        }
        currentRequest = currentRequest!.copyWith(totalBudget: budget);
        break;
      case ItineraryCommandAction.replaceOutdoor:
        final targetDay = command.dayNumber ?? selectedDay;
        if (targetDay == null) {
          _indoorOnlyDays.addAll(
            List<int>.generate(currentRequest!.days, (index) => index + 1),
          );
        } else {
          _indoorOnlyDays.add(targetDay);
        }
        final outdoorIds = itinerary!.days
            .where((day) => targetDay == null || day.dayNumber == targetDay)
            .expand((day) => day.placeItems)
            .where((item) => !item.place!.indoor)
            .map((item) => item.place!.id);
        _commandExcludedIds.addAll(outdoorIds);
        break;
    }
    _regenerationExcludedIds.clear();
  }

  Future<void> save([TripRequest? request]) async {
    final generated = itinerary;
    final effectiveRequest = request ?? currentRequest;
    if (generated == null || effectiveRequest == null || isSaving) return;

    isSaving = true;
    saveErrorMessage = null;
    notifyListeners();
    try {
      await _storageRepository.save(
        request: effectiveRequest,
        itinerary: generated,
      );
      isSaved = true;
    } catch (error) {
      saveErrorMessage = 'Không thể lưu lịch trình: $error';
      rethrow;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _build(TripRequest request) async {
    isLoading = true;
    isSaved = false;
    errorMessage = null;
    notifyListeners();

    try {
      final places = await _placeRepository.getAllPlaces();
      final rankedCandidates = _recommendationEngine.recommend(
        request: request,
        places: places,
        limit: 75,
      );
      var candidates = _filteredCandidates(rankedCandidates);
      if (candidates.length < _minimumPlaceCount(request)) {
        _regenerationExcludedIds.clear();
        candidates = _filteredCandidates(rankedCandidates);
      }
      itinerary = _itineraryBuilder.build(
        request: request,
        scoredPlaces: candidates,
        dayPaces: _dayPaces,
        dayStartMinutes: _dayStartMinutes,
        indoorOnlyDays: _indoorOnlyDays,
      );
      if (itinerary!.days.length != request.days) {
        throw StateError('Không thể tạo đủ ${request.days} ngày.');
      }
    } catch (error) {
      errorMessage = 'Không thể tạo lịch trình: $error';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<ScoredPlace> _filteredCandidates(List<ScoredPlace> candidates) {
    return candidates
        .where(
          (candidate) =>
              !_commandExcludedIds.contains(candidate.place.id) &&
              !_regenerationExcludedIds.contains(candidate.place.id),
        )
        .toList(growable: false);
  }

  int _minimumPlaceCount(TripRequest request) {
    var count = 0;
    for (var day = 1; day <= request.days; day++) {
      count += switch (_dayPaces[day] ?? request.pace) {
        'packed' => 4,
        'balanced' => 3,
        _ => 2,
      };
    }
    return count;
  }

  String _successMessage(ItineraryCommand command) {
    final message = switch (command.action) {
      ItineraryCommandAction.removePlace => 'Đã bỏ địa điểm và tối ưu lại.',
      ItineraryCommandAction.addCategory =>
        'Đã thêm sở thích và tạo lại lịch trình.',
      ItineraryCommandAction.adjustDayPace =>
        'Đã điều chỉnh nhịp độ của ngày được chọn.',
      ItineraryCommandAction.adjustDayStart =>
        'Đã đổi giờ bắt đầu và sắp xếp lại ngày được chọn.',
      ItineraryCommandAction.updateBudget =>
        'Đã cập nhật ngân sách và tối ưu lại.',
      ItineraryCommandAction.replaceOutdoor =>
        'Đã thay các điểm ngoài trời phù hợp với trời mưa.',
    };
    return command.usedLocalFallback
        ? '$message Đã dùng chế độ dự phòng vì backend không kết nối.'
        : message;
  }
}
