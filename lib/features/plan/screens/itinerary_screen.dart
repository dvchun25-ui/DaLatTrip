import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../domain/entities/generated_itinerary.dart';
import '../../../domain/entities/itinerary_day.dart';
import '../../../domain/entities/itinerary_item.dart';
import '../../../domain/entities/trip_request.dart';
import '../../places/widgets/place_image.dart';
import '../controllers/itinerary_controller.dart';
import '../widgets/itinerary_command_sheet.dart';
import 'route_map_screen.dart';

/// Lịch trình thật được tạo từ TripRequest và dataset địa điểm.
class ItineraryScreen extends StatefulWidget {
  final TripRequest request;
  final ItineraryController? controller;
  final GeneratedItinerary? initialItinerary;

  const ItineraryScreen({
    super.key,
    required this.request,
    this.controller,
    this.initialItinerary,
  });

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  late final ItineraryController _controller;
  late final bool _ownsController;
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        ItineraryController(initialItinerary: widget.initialItinerary);
    _controller.currentRequest ??= widget.request;
    _controller.addListener(_onControllerChanged);
    if (_controller.itinerary == null) {
      _controller.generate(widget.request);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _regenerate() async {
    _selectedDayIndex = 0;
    await _controller.regenerate();
    if (!mounted || _controller.errorMessage != null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã tạo một phương án lịch trình mới.')),
    );
  }

  Future<void> _showChangePlaceSheet(ItineraryDay day) async {
    if (day.placeItems.isEmpty) return;
    final placeId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn địa điểm muốn đổi',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Hệ thống sẽ chọn địa điểm thay thế và tối ưu lại thời gian.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: day.placeItems.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = day.placeItems[index];
                    final place = item.place!;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: PlaceImage(
                        place: place,
                        width: 52,
                        height: 52,
                        borderRadius: 12,
                      ),
                      title: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(item.timeLabel),
                      trailing: const Icon(Icons.swap_horiz_rounded),
                      onTap: () => Navigator.of(sheetContext).pop(place.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (placeId == null || !mounted) return;
    await _controller.replacePlace(_controller.currentRequest!, placeId);
    if (!mounted || _controller.errorMessage != null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã đổi địa điểm và tối ưu lại lịch trình.'),
      ),
    );
  }

  Future<void> _saveItinerary() async {
    try {
      await _controller.save();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu lịch trình trên thiết bị.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.saveErrorMessage ?? 'Không thể lưu lịch trình.',
          ),
        ),
      );
    }
  }

  Future<void> _showAiCommandSheet(ItineraryDay day) async {
    final draft = await showModalBottomSheet<ItineraryCommandDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => ItineraryCommandSheet(day: day),
    );
    if (draft == null || !mounted) return;
    await _controller.applyCommand(
      draft.message,
      selectedPlaceId: draft.selectedPlaceId,
      selectedDay: day.dayNumber,
    );
    if (!mounted) return;
    final message =
        _controller.commandErrorMessage ?? _controller.lastCommandMessage;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
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
          'Lịch trình gợi ý',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Xem bản đồ',
            icon: const Icon(Icons.map_outlined, size: 22),
            color: AppColors.primary,
            onPressed: _controller.itinerary == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RouteMapScreen(
                        itinerary: _controller.itinerary!,
                        transport:
                            _controller.currentRequest?.transport ??
                            widget.request.transport,
                        initialDayIndex: _selectedDayIndex,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Sửa yêu cầu ban đầu',
            icon: const Icon(Icons.tune_rounded, size: 21),
            color: AppColors.textSecondary,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              _controller.isApplyingCommand
                  ? 'Đang áp dụng góp ý và tạo lại lịch trình...'
                  : 'Đang tối ưu lịch trình gần nhau...',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_controller.errorMessage != null) {
      return _ErrorView(
        message: _controller.errorMessage!,
        onRetry: () =>
            _controller.generate(_controller.currentRequest ?? widget.request),
      );
    }

    final itinerary = _controller.itinerary;
    if (itinerary == null || itinerary.days.isEmpty) {
      return const Center(child: Text('Chưa có lịch trình phù hợp.'));
    }
    if (_selectedDayIndex >= itinerary.days.length) {
      _selectedDayIndex = 0;
    }
    final day = itinerary.days[_selectedDayIndex];

    return Stack(
      children: [
        Column(
          children: [
            _buildTopSection(itinerary),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 150),
                children: [
                  if (itinerary.warnings.isNotEmpty)
                    _buildWarning(itinerary.warnings),
                  _buildDayHeading(day),
                  const SizedBox(height: 14),
                  ...List.generate(
                    day.items.length,
                    (index) => _buildTimelineItem(
                      day.items[index],
                      index == day.items.length - 1,
                    ),
                  ),
                ],
              ),
            ),
            _buildBottomActions(),
          ],
        ),
        if (_controller.isApplyingCommand)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.18),
              child: Center(
                child: Container(
                  width: 270,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 15),
                      Text(
                        'AI đang hiểu yêu cầu...',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Sau đó thuật toán sẽ tạo lại lịch trình.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTopSection(GeneratedItinerary itinerary) {
    final placeCount = itinerary.days.fold<int>(
      0,
      (sum, day) => sum + day.placeItems.length,
    );
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Column(
        children: [
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: itinerary.days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => _buildDayTab(index),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _Metric(
                  icon: Icons.place_outlined,
                  value: '$placeCount điểm',
                  label: 'Địa điểm',
                ),
                const _MetricDivider(),
                _Metric(
                  icon: Icons.route_outlined,
                  value: '${itinerary.totalDistance.toStringAsFixed(1)} km',
                  label: 'Quãng đường',
                ),
                const _MetricDivider(),
                _Metric(
                  icon: Icons.payments_outlined,
                  value: _compactMoney(itinerary.totalCost),
                  label: 'Dự kiến',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTab(int index) {
    final isSelected = _selectedDayIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedDayIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 88,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF2F5F3),
          borderRadius: BorderRadius.circular(19),
        ),
        child: Text(
          'Ngày ${index + 1}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildWarning(List<String> warnings) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFEA580C),
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              warnings.map((warning) => '• $warning').join('\n'),
              style: const TextStyle(
                color: Color(0xFF9A3412),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeading(ItineraryDay day) {
    final firstPlace = day.placeItems.isEmpty ? null : day.placeItems.first;
    final lastPlace = day.placeItems.isEmpty ? null : day.placeItems.last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ngày ${day.dayNumber}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          firstPlace == null || lastPlace == null
              ? 'Chưa có địa điểm phù hợp'
              : '${firstPlace.timeLabel.split(' - ').first} – ${lastPlace.timeLabel.split(' - ').last}  •  ${day.placeItems.length} địa điểm',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _DayMetricChip(
              icon: Icons.route_outlined,
              label: '${day.totalDistance.toStringAsFixed(1)} km',
            ),
            _DayMetricChip(
              icon: Icons.payments_outlined,
              label: 'Tổng ngày: ${_money(day.totalCost)}',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineItem(ItineraryItem item, bool isLast) {
    final style = _styleFor(item.type);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: style.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: style.color.withValues(alpha: 0.2),
                        blurRadius: 7,
                      ),
                    ],
                  ),
                  child: Icon(style.icon, color: Colors.white, size: 13),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: const Color(0xFFD6E2DC),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: item.type == ItineraryItemType.place
                ? _buildPlaceCard(item, style)
                : _buildUtilityCard(item, style),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(ItineraryItem item, _ItemStyle style) {
    final place = item.place!;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEEA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlaceImage(place: place, width: 76, height: 82, borderRadius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.timeLabel,
                  style: TextStyle(
                    color: style.color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    if (place.rating != null)
                      _TinyInfo(
                        icon: Icons.star_rounded,
                        text: place.rating!.toStringAsFixed(1),
                        color: const Color(0xFFF59E0B),
                      ),
                    _TinyInfo(
                      icon: Icons.payments_outlined,
                      text: item.estimatedCost == 0
                          ? 'Miễn phí'
                          : _money(item.estimatedCost),
                    ),
                  ],
                ),
                if (item.note != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Lý do: ${item.note!}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilityCard(ItineraryItem item, _ItemStyle style) {
    final isTravel = item.type == ItineraryItemType.travel;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(style.icon, color: style.color, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isTravel && item.distanceKm > 0
                      ? '${item.timeLabel}  •  ${item.distanceKm.toStringAsFixed(1)} km'
                      : item.timeLabel,
                  style: TextStyle(
                    color: style.color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (item.note != null)
            Tooltip(
              message: item.note!,
              child: Icon(
                Icons.info_outline_rounded,
                color: style.color.withValues(alpha: 0.75),
                size: 17,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final itinerary = _controller.itinerary;
    final selectedDay = itinerary == null || itinerary.days.isEmpty
        ? null
        : itinerary.days[_selectedDayIndex];
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _SecondaryAction(
                  icon: Icons.refresh_rounded,
                  label: 'Tạo lại',
                  onTap: _regenerate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SecondaryAction(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Lệnh AI',
                  onTap: selectedDay == null || _controller.isApplyingCommand
                      ? null
                      : () => _showAiCommandSheet(selectedDay),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SecondaryAction(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Đổi điểm',
                  onTap: selectedDay == null
                      ? null
                      : () => _showChangePlaceSheet(selectedDay),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _controller.isSaving ? null : _saveItinerary,
              icon: _controller.isSaving
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _controller.isSaved
                          ? Icons.check_circle_rounded
                          : Icons.bookmark_add_outlined,
                      size: 19,
                    ),
              label: Text(
                _controller.isSaved ? 'Đã lưu lịch trình' : 'Lưu lịch trình',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.7,
                ),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _ItemStyle _styleFor(ItineraryItemType type) {
    return switch (type) {
      ItineraryItemType.place => const _ItemStyle(
        color: AppColors.primary,
        background: AppColors.mintBadgeLight,
        icon: Icons.location_on_rounded,
      ),
      ItineraryItemType.travel => const _ItemStyle(
        color: Color(0xFF2563EB),
        background: Color(0xFFEFF6FF),
        icon: Icons.directions_rounded,
      ),
      ItineraryItemType.meal => const _ItemStyle(
        color: Color(0xFFEA580C),
        background: Color(0xFFFFF4ED),
        icon: Icons.restaurant_rounded,
      ),
      ItineraryItemType.rest => const _ItemStyle(
        color: Color(0xFF7C3AED),
        background: Color(0xFFF5F3FF),
        icon: Icons.self_improvement_rounded,
      ),
    };
  }

  String _money(int value) {
    return '${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}đ';
  }

  String _compactMoney(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}tr';
    }
    if (value >= 1000) return '${(value / 1000).round()}k';
    return '$valueđ';
  }
}

class _DayMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DayMetricChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.mintBadgeLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4F7F5),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 19,
                color: onTap == null ? AppColors.textMuted : AppColors.primary,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: onTap == null
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemStyle {
  final Color color;
  final Color background;
  final IconData icon;

  const _ItemStyle({
    required this.color,
    required this.background,
    required this.icon,
  });
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _Metric({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: AppColors.divider,
    );
  }
}

class _TinyInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _TinyInfo({
    required this.icon,
    required this.text,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.route_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
