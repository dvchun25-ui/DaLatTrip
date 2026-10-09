import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../data/repositories/mapbox_route_repository_impl.dart';
import '../../../domain/entities/generated_itinerary.dart';
import '../../../domain/entities/itinerary_day.dart';
import '../../../domain/entities/itinerary_item.dart';
import '../../../domain/entities/map_route.dart' as domain;
import '../../../domain/repositories/map_route_repository.dart';
import '../../places/widgets/place_image.dart';

class RouteMapScreen extends StatefulWidget {
  final GeneratedItinerary itinerary;
  final String transport;
  final int initialDayIndex;
  final MapRouteRepository? routeRepository;

  const RouteMapScreen({
    super.key,
    required this.itinerary,
    required this.transport,
    this.initialDayIndex = 0,
    this.routeRepository,
  });

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  static const _mapboxToken = String.fromEnvironment('MAPBOX_PUBLIC_TOKEN');

  late final MapRouteRepository _routeRepository;
  final LocationService _locationService = LocationService();
  late int _selectedDayIndex;
  int _selectedPlaceIndex = 0;

  MapboxMap? _mapboxMap;
  PolylineAnnotationManager? _polylineManager;
  CircleAnnotationManager? _circleManager;
  PointAnnotationManager? _pointManager;

  domain.MapRoute? _route;
  geo.Position? _userPosition;
  bool _isLoading = false;
  String? _warning;

  ItineraryDay get _selectedDay => widget.itinerary.days[_selectedDayIndex];

  @override
  void initState() {
    super.initState();
    _routeRepository = widget.routeRepository ?? MapboxRouteRepositoryImpl();
    _selectedDayIndex = widget.initialDayIndex.clamp(
      0,
      widget.itinerary.days.length - 1,
    );
    _initUserLocation();
    _loadRoute();
  }

  Future<void> _initUserLocation() async {
    final pos = await _locationService.getCurrentLocation();
    if (mounted && pos != null) {
      setState(() => _userPosition = pos);
      await _drawRoute();
    }
  }

  Future<void> _loadRoute() async {
    final day = _selectedDay;
    final coordinates = day.placeItems
        .where(
          (item) =>
              item.place?.latitude != null && item.place?.longitude != null,
        )
        .map(
          (item) => domain.MapCoordinate(
            latitude: item.place!.latitude!,
            longitude: item.place!.longitude!,
          ),
        )
        .toList(growable: false);

    setState(() {
      _isLoading = true;
      _warning = null;
    });
    try {
      final result = await _routeRepository.getRoute(
        coordinates: coordinates,
        transport: widget.transport,
      );
      if (!mounted) return;
      setState(() => _route = result);
    } catch (_) {
      if (!mounted) return;
      final travelMinutes = day.items
          .where((item) => item.type == ItineraryItemType.travel)
          .fold<int>(0, (sum, item) => sum + item.durationMinutes);
      setState(() {
        _route = domain.MapRoute(
          coordinates: coordinates,
          distanceKm: day.totalDistance,
          durationMinutes: travelMinutes,
          estimated: true,
        );
        _warning =
            'Đang kết nối các điểm dừng theo lịch trình (Multi-stop Route).';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    await _drawRoute();
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _polylineManager = await mapboxMap.annotations
        .createPolylineAnnotationManager();
    _circleManager = await mapboxMap.annotations
        .createCircleAnnotationManager();
    _pointManager = await mapboxMap.annotations.createPointAnnotationManager();
    await _drawRoute();
  }

  Future<void> _drawRoute() async {
    final mapboxMap = _mapboxMap;
    final route = _route;
    if (mapboxMap == null || route == null) return;

    await _polylineManager?.deleteAll();
    await _circleManager?.deleteAll();
    await _pointManager?.deleteAll();

    // 1. Vẽ đường lộ trình nối liền các điểm (Multi-stop Route Polyline)
    final routePositions = route.coordinates
        .map((point) => Position(point.longitude, point.latitude))
        .toList(growable: false);
    if (routePositions.length >= 2) {
      await _polylineManager?.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: routePositions),
          lineColor: AppColors.primary.toARGB32(),
          lineWidth: 5,
          lineBorderColor: Colors.white.toARGB32(),
          lineBorderWidth: 1.5,
        ),
      );
    }

    // 2. Vẽ marker vị trí GPS của người dùng (nếu có)
    final userPos = _userPosition;
    if (userPos != null) {
      final userGeometry = Point(
        coordinates: Position(userPos.longitude, userPos.latitude),
      );
      await _circleManager?.create(
        CircleAnnotationOptions(
          geometry: userGeometry,
          circleColor: const Color(0xFF1E88E5).toARGB32(),
          circleRadius: 10,
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeWidth: 3,
        ),
      );
    }

    // 3. Vẽ marker các điểm tham quan được đánh số (1, 2, 3...)
    final waypoints = _selectedDay.placeItems
        .where(
          (item) =>
              item.place?.latitude != null && item.place?.longitude != null,
        )
        .toList(growable: false);
    for (var index = 0; index < waypoints.length; index++) {
      final place = waypoints[index].place!;
      final isSelected = index == _selectedPlaceIndex;
      final geometry = Point(
        coordinates: Position(place.longitude!, place.latitude!),
      );
      await _circleManager?.create(
        CircleAnnotationOptions(
          geometry: geometry,
          circleColor: (isSelected ? const Color(0xFFE65100) : AppColors.primary)
              .toARGB32(),
          circleRadius: isSelected ? 15 : 12,
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeWidth: 2.5,
        ),
      );
      await _pointManager?.create(
        PointAnnotationOptions(
          geometry: geometry,
          textField: '${index + 1}',
          textColor: Colors.white.toARGB32(),
          textSize: 12,
          textHaloColor: AppColors.primary.toARGB32(),
          textHaloWidth: 0.5,
        ),
      );
    }
    _focusCoordinates(mapboxMap, route.coordinates);
  }

  void _focusCoordinates(
    MapboxMap mapboxMap,
    List<domain.MapCoordinate> coordinates,
  ) {
    if (coordinates.isEmpty) return;
    final minLatitude = coordinates
        .map((point) => point.latitude)
        .reduce(math.min);
    final maxLatitude = coordinates
        .map((point) => point.latitude)
        .reduce(math.max);
    final minLongitude = coordinates
        .map((point) => point.longitude)
        .reduce(math.min);
    final maxLongitude = coordinates
        .map((point) => point.longitude)
        .reduce(math.max);
    final spread = math.max(
      maxLatitude - minLatitude,
      maxLongitude - minLongitude,
    );
    final zoom = switch (spread) {
      < 0.015 => 14.2,
      < 0.04 => 12.6,
      < 0.09 => 11.2,
      _ => 9.8,
    };
    mapboxMap.setCamera(
      CameraOptions(
        center: Point(
          coordinates: Position(
            (minLongitude + maxLongitude) / 2,
            (minLatitude + maxLatitude) / 2,
          ),
        ),
        zoom: zoom,
      ),
    );
  }

  void _centerOnUserLocation() {
    final pos = _userPosition;
    final mapboxMap = _mapboxMap;
    if (pos == null || mapboxMap == null) return;
    mapboxMap.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(pos.longitude, pos.latitude)),
        zoom: 14.5,
      ),
    );
  }

  void _focusPlace(int index) {
    final placeItems = _selectedDay.placeItems;
    if (index < 0 || index >= placeItems.length) return;
    final place = placeItems[index].place;
    final mapboxMap = _mapboxMap;
    setState(() => _selectedPlaceIndex = index);
    _drawRoute();

    if (place != null && place.latitude != null && place.longitude != null && mapboxMap != null) {
      mapboxMap.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(place.longitude!, place.latitude!),
          ),
          zoom: 14.5,
        ),
      );
    }
  }

  Future<void> _selectDay(int index) async {
    if (index == _selectedDayIndex) return;
    setState(() {
      _selectedDayIndex = index;
      _selectedPlaceIndex = 0;
    });
    await _loadRoute();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F1EC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Bản đồ lộ trình Đà Lạt',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildMap()),
          Positioned(top: 12, left: 16, right: 16, child: _buildTopPanel()),

          // Nút vị trí GPS của tôi
          Positioned(
            right: 16,
            bottom: 150 + MediaQuery.paddingOf(context).bottom,
            child: FloatingActionButton.small(
              heroTag: 'gps_fab',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 4,
              onPressed: _centerOnUserLocation,
              child: const Icon(Icons.my_location_rounded, size: 22),
            ),
          ),

          // Carousel / Card hiển thị địa điểm trong ngày
          Positioned(
            left: 16,
            right: 16,
            bottom: 20 + MediaQuery.paddingOf(context).bottom,
            child: _buildPlacesCarousel(),
          ),
          if (_isLoading)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (_mapboxToken.isEmpty) {
      return Container(
        color: const Color(0xFFE9F1EC),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: const Text(
          'Thiếu MAPBOX_PUBLIC_TOKEN. Hãy chạy app với token Mapbox hợp lệ.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return MapWidget(
      key: const ValueKey('dalattrip-mapbox-map'),
      styleUri: MapboxStyles.MAPBOX_STREETS,
      viewport: CameraViewportState(
        center: Point(coordinates: Position(108.4383, 11.9404)),
        zoom: 11.5,
      ),
      onMapCreated: _onMapCreated,
    );
  }

  Widget _buildTopPanel() {
    final route = _route;
    return Column(
      children: [
        Container(
          height: 42,
          padding: const EdgeInsets.all(4),
          decoration: _panelDecoration(),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.itinerary.days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 5),
            itemBuilder: (context, index) {
              final selected = index == _selectedDayIndex;
              return GestureDetector(
                onTap: () => _selectDay(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 84,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    'Ngày ${index + 1}',
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: _panelDecoration(),
          child: Row(
            children: [
              Expanded(
                child: _MapMetric(
                  label: 'Tổng quãng đường',
                  value: '${(route?.distanceKm ?? 0).toStringAsFixed(1)} km',
                ),
              ),
              Container(height: 28, width: 1, color: AppColors.divider),
              Expanded(
                child: _MapMetric(
                  label: 'Thời gian di chuyển',
                  value: _durationLabel(route?.durationMinutes ?? 0),
                  primary: true,
                ),
              ),
            ],
          ),
        ),
        if (_warning != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Text(
              _warning!,
              style: const TextStyle(color: Color(0xFF9A3412), fontSize: 11),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlacesCarousel() {
    final placeItems = _selectedDay.placeItems;
    if (placeItems.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 105,
      child: PageView.builder(
        itemCount: placeItems.length,
        controller: PageController(
          initialPage: _selectedPlaceIndex.clamp(0, placeItems.length - 1),
          viewportFraction: 0.95,
        ),
        onPageChanged: _focusPlace,
        itemBuilder: (context, index) {
          final item = placeItems[index];
          final place = item.place;
          if (place == null) return const SizedBox.shrink();

          final distanceToUser = _locationService.getDistanceToPlaceInKm(
            place.latitude,
            place.longitude,
          );

          return GestureDetector(
            onTap: () => _focusPlace(index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(10),
              decoration: _panelDecoration(radius: 16),
              child: Row(
                children: [
                  Stack(
                    children: [
                      PlaceImage(
                        place: place,
                        width: 76,
                        height: 76,
                        borderRadius: 12,
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.timeLabel,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.near_me_outlined,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              distanceToUser != null
                                  ? 'Cách bạn ${_locationService.formatDistance(distanceToUser)}'
                                  : (place.address ?? 'Đà Lạt'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _panelDecoration({double radius = 13}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 14,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  String _durationLabel(int minutes) {
    if (minutes < 60) return '$minutes phút';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    return remaining == 0 ? '$hours giờ' : '$hours giờ $remaining phút';
  }
}

class _MapMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool primary;

  const _MapMetric({
    required this.label,
    required this.value,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: primary ? AppColors.primary : AppColors.textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
