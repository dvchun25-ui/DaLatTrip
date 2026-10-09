import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../domain/entities/clarification_question.dart';

class ClarificationQuestionCard extends StatelessWidget {
  final ClarificationQuestion question;
  final bool enabled;
  final ValueChanged<ClarificationOption> onSelected;

  const ClarificationQuestionCard({
    super.key,
    required this.question,
    required this.onSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (question.quickOptions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: question.quickOptions
                  .map(
                    (option) => ActionChip(
                      label: Text(option.label),
                      onPressed: enabled ? () => onSelected(option) : null,
                      backgroundColor: AppColors.mintBadgeLight,
                      side: const BorderSide(color: Color(0xFFCFE2D7)),
                      labelStyle: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Hoặc nhập câu trả lời khác ở ô bên dưới.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}
