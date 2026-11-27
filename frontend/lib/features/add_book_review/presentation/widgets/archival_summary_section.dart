import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class ArchivalSummarySection extends StatelessWidget {
  final String summary;

  const ArchivalSummarySection({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.description_outlined,
              size: 18,
              color: DSColors.primary,
            ),
            const SizedBox(width: DSSpacing.sm),
            Text(
              "Archival Summary",
              style: IvoryTheme.smallCapsLabel.copyWith(
                color: DSColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: DSSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DSSpacing.md),
          decoration: BoxDecoration(
            color: DSColors.surface,
            borderRadius: BorderRadius.circular(DSRadius.lg),
          ),
          child: Text(
            summary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: DSColors.textLight,
            ),
          ),
        ),
      ],
    );
  }
}
