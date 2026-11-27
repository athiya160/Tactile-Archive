import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../tokens/app_tokens.dart';

class PriceRow extends StatelessWidget {
  final double? price;
  final double? originalPrice;
  final double? discountPercentage;
  final bool isLarge;

  const PriceRow({
    super.key,
    this.price,
    this.originalPrice,
    this.discountPercentage,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    if (price == null || price == 0) {
      return Text(
        'Free',
        style:
            (isLarge
                    ? Theme.of(context).textTheme.titleLarge
                    : Theme.of(context).textTheme.labelLarge)
                ?.copyWith(color: AppColors.primary),
      );
    }

    final mainPriceWidget = Text(
      '\$${price!.toStringAsFixed(2)}',
      style: (isLarge ? IvoryTheme.priceLarge : IvoryTheme.priceMedium)
          .copyWith(color: AppColors.primary),
    );

    if (isLarge) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (originalPrice != null &&
              discountPercentage != null &&
              discountPercentage! > 0)
            Row(
              children: [
                Text(
                  '\$${originalPrice!.toStringAsFixed(2)}',
                  style: IvoryTheme.priceSmall.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: AppColors.outline.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '-${discountPercentage!.toInt()}%',
                  style: IvoryTheme.priceSmall.copyWith(color: AppColors.error),
                ),
              ],
            ),
          mainPriceWidget,
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          mainPriceWidget,
          if (originalPrice != null &&
              discountPercentage != null &&
              discountPercentage! > 0) ...[
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                '\$${originalPrice!.toStringAsFixed(2)}',
                style: IvoryTheme.priceSmall.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: AppColors.outline.withValues(alpha: 0.6),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '-${discountPercentage!.toInt()}%',
              style: IvoryTheme.priceSmall.copyWith(color: AppColors.error),
            ),
          ],
        ],
      );
    }
  }
}
