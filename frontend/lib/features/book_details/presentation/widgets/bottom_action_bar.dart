import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import 'package:libri_flow/core/design_system/tokens/ds_colors.dart';

class BottomActionBar extends StatelessWidget {
  final double price;
  final double? originalPrice;
  final double? discountPercentage;
  final VoidCallback onBorrow;
  final VoidCallback? onRent;
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow;
  final int stock;

  const BottomActionBar({
    super.key,
    required this.price,
    this.originalPrice,
    this.discountPercentage,
    required this.onBorrow,
    required this.onRent,
    required this.onAddToCart,
    required this.onBuyNow,
    this.stock = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        border: const Border(top: BorderSide(color: Color(0x4DC3C8C1))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'RENT FROM',
                            style: IvoryTheme.statusLabel.copyWith(
                              color: DSColors.charcoal,
                            ),
                          ),
                          if (stock == 0) ...[
                            const SizedBox(width: 8),
                            const Text(
                              'Out of Stock',
                              style: TextStyle(
                                color: Color(0xFFDA3633),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (discountPercentage != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x1ABA1A1A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${discountPercentage!.toStringAsFixed(0)}% OFF',
                                style: const TextStyle(
                                  color: Color(0xFFBA1A1A),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹${price.toStringAsFixed(0)}',
                            style: IvoryTheme.priceLarge.copyWith(
                              color: DSColors.deepForestGreen,
                            ),
                          ),
                          if (originalPrice != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '₹${originalPrice!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: DSColors.charcoal,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                          const SizedBox(width: 4),
                          const Text(
                            '/ 14 days',
                            style: TextStyle(
                              fontSize: 12,
                              color: DSColors.charcoal,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons row — Borrow & Rent
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'BORROW',
                    icon: Icons.book_outlined,
                    onPressed: stock > 0 ? onBorrow : null,
                    isPrimary: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    label: 'RENT',
                    icon: Icons.access_time_outlined,
                    onPressed: stock > 0 ? onRent : null,
                    isPrimary: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Add to Cart and Buy row
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'ADD TO CART',
                    icon: Icons.shopping_cart_outlined,
                    onPressed: stock > 0 ? onAddToCart : null,
                    isPrimary: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    label: 'BUY',
                    icon: Icons.shopping_bag_outlined,
                    onPressed: stock > 0 ? onBuyNow : null,
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? DSColors.deepForestGreen
              : DSColors.warmIvory,
          foregroundColor: isPrimary ? Colors.white : DSColors.deepForestGreen,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isPrimary
                ? BorderSide.none
                : const BorderSide(color: Color(0xFF737973)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                style: IvoryTheme.formFieldLabel.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
