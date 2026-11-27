import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/standard_check_item.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class ArchiveStandardsSection extends StatelessWidget {
  final List<StandardCheckItem> standards;

  const ArchiveStandardsSection({super.key, required this.standards});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Archive Standards",
          style: IvoryTheme.smallCapsLabel.copyWith(color: DSColors.primary),
        ),
        const SizedBox(height: DSSpacing.md),
        Container(
          padding: const EdgeInsets.all(DSSpacing.md),
          decoration: BoxDecoration(
            color: DSColors.surface,
            borderRadius: BorderRadius.circular(DSRadius.lg),
          ),
          child: Column(
            children: standards.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: DSSpacing.sm),
                child: Row(
                  children: [
                    Icon(
                      item.isChecked
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 20,
                      color: item.isChecked
                          ? DSColors.primary
                          : DSColors.border,
                    ),
                    const SizedBox(width: DSSpacing.md),
                    Expanded(
                      child: Text(
                        item.text,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: DSColors.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
