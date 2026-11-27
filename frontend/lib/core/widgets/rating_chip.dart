import 'package:flutter/material.dart';
import '../tokens/app_tokens.dart';

class RatingChip extends StatelessWidget {
  final double rating;
  final Color? color;

  const RatingChip({super.key, required this.rating, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: 14, color: color ?? AppColors.primaryContainer),
        const SizedBox(width: AppSpacing.xs),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.primary,
            fontSize: 12, // text-xs
          ),
        ),
      ],
    );
  }
}
