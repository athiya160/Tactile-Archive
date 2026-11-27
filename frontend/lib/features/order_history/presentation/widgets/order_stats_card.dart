import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/order_history_stats.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class OrderStatsCard extends StatelessWidget {
  final OrderHistoryStats stats;

  const OrderStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24), // p-6 per spec
      decoration: BoxDecoration(
        color: DSColors.primary,
        borderRadius: BorderRadius.circular(16), // rounded-2xl per spec
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MEMBER STATISTICS',
            style: IvoryTheme.smallCapsLabel.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: DSSpacing.sm),
          Text(
            'Total Archive Value',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: DSSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$${stats.totalArchiveValue.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 30, // text-3xl per spec
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.8, // tracking-tight
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: DSSpacing.sm),
              Text(
                'USD TOTAL',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.white60),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.xl),
          Row(
            children: [
              _StatIndicator(label: '${stats.purchaseCount} PURCHASES'),
              const SizedBox(width: DSSpacing.xl),
              _StatIndicator(label: '${stats.rentalCount} RENTALS'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatIndicator extends StatelessWidget {
  final String label;

  const _StatIndicator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: DSColors.borderLight,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: DSSpacing.sm),
        Text(
          label,
          style: IvoryTheme.statusLabel.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}
