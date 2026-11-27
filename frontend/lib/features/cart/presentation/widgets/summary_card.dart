import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class SummaryCard extends StatelessWidget {
  final double subtotal;
  final double archiveFee;
  final double shippingFee;
  final double total;
  final VoidCallback? onCheckout;

  const SummaryCard({
    super.key,
    required this.subtotal,
    required this.archiveFee,
    required this.shippingFee,
    required this.total,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.xl),
      decoration: BoxDecoration(
        color: DSColors.borderLight,
        borderRadius: BorderRadius.circular(DSRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Summary', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: DSSpacing.xl),
          _SummaryRow(
            label: 'Subtotal',
            value: '₹${subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: DSSpacing.md),
          _SummaryRow(
            label: 'Archive Fee',
            value: '₹${archiveFee.toStringAsFixed(2)}',
          ),
          const SizedBox(height: DSSpacing.md),
          _SummaryRow(
            label: 'Shipping (Purchase items)',
            value: shippingFee == 0
                ? 'FREE'
                : '₹${shippingFee.toStringAsFixed(2)}',
            valueColor: shippingFee == 0 ? DSColors.textDark : null,
          ),
          const SizedBox(height: DSSpacing.xl),
          Container(
            padding: const EdgeInsets.only(top: DSSpacing.lg),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: DSColors.borderLight, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: Theme.of(context).textTheme.titleLarge),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: DSColors.primary,
                      ),
                    ),
                    Text(
                      'INCLUSIVE OF TAXES',
                      style: IvoryTheme.statusLabel.copyWith(
                        color: DSColors.textLight.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onCheckout != null) ...[
            const SizedBox(height: DSSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [DSColors.primary, DSColors.primaryHover],
                  ),
                  borderRadius: BorderRadius.circular(DSRadius.lg),
                ),
                child: ElevatedButton(
                  onPressed: onCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: DSSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DSRadius.lg),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'PROCEED TO CHECKOUT',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: DSColors.textInverse,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: DSSpacing.sm),
                      const Icon(
                        Icons.arrow_forward,
                        color: DSColors.textInverse,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: DSSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FooterIcon(Icons.enhanced_encryption),
              const SizedBox(width: DSSpacing.md),
              _FooterIcon(Icons.payments),
              const SizedBox(width: DSSpacing.md),
              _FooterIcon(Icons.verified),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: DSColors.textLight),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? DSColors.textDark,
          ),
        ),
      ],
    );
  }
}

class _FooterIcon extends StatelessWidget {
  final IconData icon;
  const _FooterIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: 20,
      color: DSColors.textLight.withValues(alpha: 0.3),
    );
  }
}
