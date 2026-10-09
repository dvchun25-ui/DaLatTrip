import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/ai_trip_parse_result.dart';
import '../../domain/repositories/ai_trip_repository.dart';
import '../models/ai_trip_parse_result_model.dart';

class AiTripRepositoryImpl implements AiTripRepository {
  final ApiClient apiClient;

  const AiTripRepositoryImpl({required this.apiClient});

  @override
  Future<AiTripParseResult> parseTripRequest({
    required String message,
    Map<String, dynamic>? previousData,
  }) async {
    final json = await apiClient.post(
      ApiConstants.parseTripRequest,
      body: {'message': message, 'previousData': previousData},
    );
    return AiTripParseResultModel.fromJson(json);
  }
}
