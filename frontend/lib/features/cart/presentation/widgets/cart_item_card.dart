import 'package:flutter/material.dart';
import '../../../../core/widgets/book_cover_image.dart';
import '../../domain/entities/cart_item.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onIncreaseQuantity;
  final VoidCallback onDecreaseQuantity;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onIncreaseQuantity,
    required this.onDecreaseQuantity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DSRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book Cover
          ClipRRect(
            borderRadius: BorderRadius.circular(DSRadius.sm),
            child: BookCoverImage(
              url: item.coverUrl,
              width: 96,
              height: 144,
              fit: BoxFit.cover,
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
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            item.author,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: DSColors.textLight.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: DSColors.border,
                      onPressed: onRemove,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: DSSpacing.xxl),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DSSpacing.md,
                        vertical: DSSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: item.isPurchase
                            ? DSColors.primary
                            : DSColors.borderLight,
                        borderRadius: BorderRadius.circular(100.0),
                      ),
                      child: Text(
                        item.isPurchase
                            ? 'PURCHASE'
                            : 'RENT (${item.rentalDays} DAYS)',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: item.isPurchase
                              ? DSColors.textInverse
                              : DSColors.textLight,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Text(
                      '₹${item.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontSize: 18, color: DSColors.secondary),
                    ),
                  ],
                ),
                const SizedBox(height: DSSpacing.md),
                // Quantity Selector
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: DSColors.borderLight),
                        borderRadius: BorderRadius.circular(100.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 16),
                            onPressed: onDecreaseQuantity,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                          Text(
                            '${item.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            onPressed: onIncreaseQuantity,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Subtotal: ₹${(item.price * item.quantity).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: DSColors.textDark,
                        fontWeight: FontWeight.w600,
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
