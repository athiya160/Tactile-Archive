import 'package:flutter/material.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class HumanReviewCard extends StatelessWidget {
  const HumanReviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.md),
      decoration: BoxDecoration(
        color: DSColors.surface,
        borderRadius: BorderRadius.circular(DSRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info, color: DSColors.primary, size: 20),
          const SizedBox(width: DSSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Human Review',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: DSColors.primary,
                  ),
                ),
                const SizedBox(height: DSSpacing.xs),
                Text(
                  'Our librarians review all feedback within 48 hours. Thank you for contributing to the preservation of our digital collection.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DSColors.textLight,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
