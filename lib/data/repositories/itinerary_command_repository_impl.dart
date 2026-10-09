import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/itinerary_command.dart';
import '../../domain/repositories/itinerary_command_repository.dart';
import '../../domain/services/local_itinerary_command_parser.dart';
import '../models/itinerary_command_model.dart';

class ItineraryCommandRepositoryImpl implements ItineraryCommandRepository {
  final ApiClient apiClient;
  final LocalItineraryCommandParser localParser;

  const ItineraryCommandRepositoryImpl({
    required this.apiClient,
    this.localParser = const LocalItineraryCommandParser(),
  });

  @override
  Future<ItineraryCommand> parseCommand({
    required String message,
    String? selectedPlaceId,
    int? selectedDay,
    required List<ItineraryCommandPlaceContext> places,
  }) async {
    try {
      final json = await apiClient.post(
        ApiConstants.parseItineraryCommand,
        body: {
          'message': message,
          'context': {
            'selectedPlaceId': selectedPlaceId,
            'selectedDay': selectedDay,
            'places': places.map((place) => place.toJson()).toList(),
          },
        },
      );
      return ItineraryCommandModel.fromJson(json);
    } on ApiException catch (error) {
      if (error.statusCode != null) rethrow;
      final fallback = localParser.parse(
        message: message,
        selectedPlaceId: selectedPlaceId,
        selectedDay: selectedDay,
        places: places,
      );
      if (fallback != null) return fallback;
      rethrow;
    }
  }
}
