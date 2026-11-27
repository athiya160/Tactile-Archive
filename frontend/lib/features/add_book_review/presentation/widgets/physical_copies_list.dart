import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/physical_copy_review.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class PhysicalCopiesList extends StatelessWidget {
  final List<PhysicalCopyReview> copies;

  const PhysicalCopiesList({super.key, required this.copies});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 18,
              color: DSColors.primary,
            ),
            const SizedBox(width: DSSpacing.sm),
            Text(
              "Physical Copies",
              style: IvoryTheme.smallCapsLabel.copyWith(
                color: DSColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: DSSpacing.md),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: copies.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: DSSpacing.md),
          itemBuilder: (context, index) {
            final copy = copies[index];
            return _CopyItemCard(copy: copy);
          },
        ),
      ],
    );
  }
}

class _CopyItemCard extends StatelessWidget {
  final PhysicalCopyReview copy;

  const _CopyItemCard({required this.copy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.md),
      decoration: BoxDecoration(
        color: DSColors.border,
        borderRadius: BorderRadius.circular(DSRadius.lg),
        boxShadow: DSShadows.md,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DSColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              copy.icon == 'archive' ? Icons.archive : Icons.auto_stories,
              size: 20,
              color: DSColors.primary,
            ),
          ),
          const SizedBox(width: DSSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  copy.subtext,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: DSSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Wrap(
                spacing: 4,
                children: copy.chips.map((chip) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: DSColors.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      chip,
                      style: IvoryTheme.smallCapsLabel.copyWith(
                        fontSize: 8,
                        letterSpacing: 1.0,
                        color: DSColors.border,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (copy.price != null) ...[
                const SizedBox(height: 4),
                Text(
                  copy.price!,
                  style: IvoryTheme.priceSmall.copyWith(
                    color: DSColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
