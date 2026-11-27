import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/book_cover_image.dart';
import '../../domain/entities/rental_item.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class RentalItemCard extends StatelessWidget {
  final RentalItem rental;

  const RentalItemCard({super.key, required this.rental});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.md),
      decoration: BoxDecoration(
        color: DSColors.surface,
        borderRadius: BorderRadius.circular(DSRadius.lg),
        border: Border.all(color: DSColors.borderLight.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Book Cover
          ClipRRect(
            borderRadius: BorderRadius.circular(DSRadius.sm),
            child: SizedBox(
              width: 64,
              height: 96,
              child: BookCoverImage(
                url: rental.coverUrl,
                width: 64,
                height: 96,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(DSRadius.sm),
              ),
            ),
          ),
          const SizedBox(width: DSSpacing.lg),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        rental.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: DSColors.primary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: DSSpacing.sm),
                    Text(
                      rental.dueLabel.toUpperCase(),
                      style: IvoryTheme.smallCapsLabel.copyWith(
                        color: rental.dueLabel.contains('Due')
                            ? DSColors.error
                            : DSColors.textLight,
                      ),
                    ),
                  ],
                ),
                Text(
                  rental.author,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: DSColors.textLight),
                ),
                const SizedBox(height: DSSpacing.md),
                // Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "PROGRESS",
                          style: IvoryTheme.statusLabel.copyWith(
                            color: DSColors.border,
                          ),
                        ),
                        Text(
                          "${(rental.progress * 100).toInt()}%",
                          style: IvoryTheme.statusLabel.copyWith(
                            color: DSColors.border,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DSSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100.0),
                      child: Container(
                        height: 6,
                        color: DSColors.borderLight,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: rental.progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: DSColors.primary,
                              borderRadius: BorderRadius.circular(100.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
