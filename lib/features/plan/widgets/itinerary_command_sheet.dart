import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../domain/entities/itinerary_day.dart';

class ItineraryCommandDraft {
  final String message;
  final String? selectedPlaceId;

  const ItineraryCommandDraft({
    required this.message,
    required this.selectedPlaceId,
  });
}

class ItineraryCommandSheet extends StatefulWidget {
  final ItineraryDay day;

  const ItineraryCommandSheet({super.key, required this.day});

  @override
  State<ItineraryCommandSheet> createState() => _ItineraryCommandSheetState();
}

class _ItineraryCommandSheetState extends State<ItineraryCommandSheet> {
  static const _examples = [
    'Bỏ địa điểm này',
    'Thêm một quán cafe',
    'Ngày này đi nhẹ hơn',
    'Tôi muốn nghỉ ngơi, ngày này bắt đầu từ 10g',
    'Giảm ngân sách xuống 4 triệu',
    'Đổi địa điểm ngoài trời vì trời mưa',
  ];

  final _textController = TextEditingController();
  String? _selectedPlaceId;
  String? _selectionError;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    final message = _textController.text.trim();
    if (message.isEmpty) return;
    final refersToThisPlace =
        message.toLowerCase().contains('địa điểm này') ||
        message.toLowerCase().contains('dia diem nay');
    if (refersToThisPlace && _selectedPlaceId == null) {
      setState(() {
        _selectionError =
            'Hãy chọn một địa điểm vì câu lệnh có “địa điểm này”.';
      });
      return;
    }
    Navigator.of(context).pop(
      ItineraryCommandDraft(
        message: message,
        selectedPlaceId: _selectedPlaceId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sửa lịch trình bằng AI',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Ngữ cảnh: Ngày ${widget.day.dayNumber}. AI chỉ hiểu lệnh, thuật toán sẽ lập lại lịch trình.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              if (widget.day.placeItems.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Địa điểm tham chiếu (không bắt buộc)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Chỉ cần chọn khi câu lệnh có “địa điểm này”.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: widget.day.placeItems.map((item) {
                    final place = item.place!;
                    return ChoiceChip(
                      label: Text(place.name),
                      selected: _selectedPlaceId == place.id,
                      selectedColor: AppColors.mintBadgeLight,
                      onSelected: (selected) => setState(() {
                        _selectedPlaceId = selected ? place.id : null;
                        _selectionError = null;
                      }),
                    );
                  }).toList(),
                ),
                if (_selectionError != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    _selectionError!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                minLines: 2,
                maxLines: 4,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Ngày 2 đi nhẹ hơn...',
                  filled: true,
                  fillColor: const Color(0xFFF5F8F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 11),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: _examples
                    .map(
                      (example) => ActionChip(
                        label: Text(example),
                        onPressed: () {
                          setState(() {
                            _textController.text = example;
                            _selectionError = null;
                          });
                          _textController.selection = TextSelection.collapsed(
                            offset: example.length,
                          );
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('Áp dụng và tạo lại'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
