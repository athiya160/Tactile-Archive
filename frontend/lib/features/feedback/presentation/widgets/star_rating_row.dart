import 'package:flutter/material.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class StarRatingRow extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;

  const StarRatingRow({
    super.key,
    required this.rating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OVERALL EXPERIENCE',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: DSColors.textLight.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: DSSpacing.md),
        Row(
          children: List.generate(5, (index) {
            final starValue = index + 1;
            final isSelected = starValue <= rating;

            return IconButton(
              onPressed: () => onRatingChanged(starValue),
              icon: Icon(
                isSelected ? Icons.star : Icons.star_outline,
                color: isSelected ? DSColors.primary : DSColors.borderLight,
                size: 30,
              ),
              padding: const EdgeInsets.only(right: 8.0),

              constraints: const BoxConstraints(),
            );
          }),
        ),
      ],
    );
  }
}
