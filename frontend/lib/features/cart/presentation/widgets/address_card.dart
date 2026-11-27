import 'package:flutter/material.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class AddressCard extends StatelessWidget {
  final String? recipientName;
  final String? address;
  final VoidCallback onChange;

  const AddressCard({
    super.key,
    this.recipientName,
    this.address,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.lg),
      decoration: BoxDecoration(
        color: DSColors.surface,
        borderRadius: BorderRadius.circular(DSRadius.xl),
        border: Border.all(color: DSColors.borderLight.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Address',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: onChange,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  'CHANGE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: DSColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on,
                color: DSColors.textLight.withValues(alpha: 0.6),
                size: 20,
              ),
              const SizedBox(width: DSSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipientName ?? 'Add recipient',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address ?? 'Enter your delivery address',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DSColors.textLight,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
