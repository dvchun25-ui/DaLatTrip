enum CheckInMediaType { photo, video }

class CheckInEntry {
  final String id;
  final String mediaPath;
  final CheckInMediaType mediaType;
  final DateTime capturedAt;
  final double? latitude;
  final double? longitude;
  final String? placeId;
  final String placeName;
  final int durationSeconds;
  final List<String> recipients;

  const CheckInEntry({
    required this.id,
    required this.mediaPath,
    required this.mediaType,
    required this.capturedAt,
    this.latitude,
    this.longitude,
    this.placeId,
    required this.placeName,
    this.durationSeconds = 0,
    this.recipients = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mediaPath': mediaPath,
      'mediaType': mediaType.name,
      'capturedAt': capturedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'placeId': placeId,
      'placeName': placeName,
      'durationSeconds': durationSeconds,
      'recipients': recipients,
    };
  }

  factory CheckInEntry.fromJson(Map<String, dynamic> json) {
    return CheckInEntry(
      id: json['id']?.toString() ?? '',
      mediaPath: json['mediaPath']?.toString() ?? '',
      mediaType: json['mediaType'] == 'video'
          ? CheckInMediaType.video
          : CheckInMediaType.photo,
      capturedAt: json['capturedAt'] != null
          ? DateTime.tryParse(json['capturedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      placeId: json['placeId']?.toString(),
      placeName: json['placeName']?.toString() ?? 'Đà Lạt',
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      recipients: List<String>.from(json['recipients'] ?? []),
    );
  }
}
