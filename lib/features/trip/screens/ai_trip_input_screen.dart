import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../plan/screens/itinerary_screen.dart';
import '../controllers/trip_planning_controller.dart';
import '../widgets/ai_question_bubble.dart';
import '../widgets/clarification_question_card.dart';
import '../widgets/trip_request_preview.dart';

class AiTripInputScreen extends StatefulWidget {
  final TripPlanningController? controller;

  const AiTripInputScreen({super.key, this.controller});

  @override
  State<AiTripInputScreen> createState() => _AiTripInputScreenState();
}

class _AiTripInputScreenState extends State<AiTripInputScreen> {
  late final TripPlanningController _controller;
  late final bool _ownsController;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _resultOpened = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TripPlanningController();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    if (_ownsController) _controller.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
      if (_controller.state == TripPlanningState.success &&
          _controller.itinerary != null &&
          _controller.tripRequest != null &&
          !_resultOpened) {
        _openResult();
      }
    });
  }

  Future<void> _openResult() async {
    if (_resultOpened || !mounted) return;
    _resultOpened = true;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItineraryScreen(
          request: _controller.tripRequest!,
          initialItinerary: _controller.itinerary!,
        ),
      ),
    );
  }

  void _reset() {
    _resultOpened = false;
    _controller.reset();
  }

  Future<void> _submit() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    await _controller.submitMessage(text);
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
        title: const Column(
          children: [
            Text(
              'Lên lịch với AI',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Gemini chỉ hiểu yêu cầu, thuật toán sẽ tạo lịch',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Bắt đầu lại',
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              children: [
                _buildIntroCard(),
                const SizedBox(height: 16),
                ..._controller.messages.map(
                  (message) => AiQuestionBubble(
                    text: message.text,
                    isUser: message.role == TripPlanningMessageRole.user,
                  ),
                ),
                if (_controller.state == TripPlanningState.askingQuestions)
                  ..._controller.questions.map(
                    (question) => ClarificationQuestionCard(
                      question: question,
                      enabled: !_controller.isBusy,
                      onSelected: _controller.answerQuickOption,
                    ),
                  ),
                if (_controller.isBusy) _buildTypingIndicator(),
                if (_controller.state == TripPlanningState.success &&
                    _controller.tripRequest != null) ...[
                  const SizedBox(height: 4),
                  TripRequestPreview(request: _controller.tripRequest!),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _openResult,
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: const Text('Tạo lịch trình phù hợp'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE5F1EA), Color(0xFFF5F9F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6E7DD)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.smart_toy_rounded, color: Colors.white),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ví dụ: “Đi Đà Lạt 3 ngày với người yêu, thích thiên nhiên và cà phê.”',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const SizedBox(
          width: 42,
          child: LinearProgressIndicator(
            minHeight: 3,
            color: AppColors.primary,
            backgroundColor: AppColors.mintBadge,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              enabled: !_controller.isBusy,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: _controller.state == TripPlanningState.success
                    ? 'Bạn có thể nhập lại để điều chỉnh...'
                    : 'Mô tả chuyến đi hoặc trả lời câu hỏi...',
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: const Color(0xFFF2F5F3),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(23),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _controller.isBusy ? null : _submit,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.textMuted,
            ),
            icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
