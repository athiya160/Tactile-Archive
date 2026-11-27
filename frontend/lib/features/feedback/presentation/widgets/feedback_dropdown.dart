import 'package:flutter/material.dart';
import '../../domain/entities/user_feedback.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class FeedbackDropdown extends StatelessWidget {
  final FeedbackReason value;
  final ValueChanged<FeedbackReason?> onChanged;

  const FeedbackDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REASON FOR WRITING',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: DSColors.textLight.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: DSSpacing.md),
          decoration: BoxDecoration(
            color: DSColors.surface,
            borderRadius: BorderRadius.circular(DSRadius.lg),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<FeedbackReason>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.expand_more, color: DSColors.textLight),
              dropdownColor: DSColors.surface,
              items: FeedbackReason.values.map((reason) {
                return DropdownMenuItem<FeedbackReason>(
                  value: reason,
                  child: Text(
                    reason.label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
