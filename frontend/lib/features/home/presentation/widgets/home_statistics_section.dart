import 'package:flutter/material.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class HomeStatisticsSection extends StatelessWidget {
  const HomeStatisticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = [
      {'label': 'Total Books', 'value': '125K+', 'icon': Icons.library_books},
      {'label': 'Active Readers', 'value': '45K+', 'icon': Icons.people},
      {'label': 'Sellers', 'value': '3.2K+', 'icon': Icons.storefront},
      {'label': 'Categories', 'value': '24', 'icon': Icons.category},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.lg),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: DSSpacing.md,
          crossAxisSpacing: DSSpacing.md,
          childAspectRatio: 1.5,
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return Container(
            decoration: BoxDecoration(
              color: DSColors.surface,
              borderRadius: BorderRadius.circular(DSRadius.lg),
              border: Border.all(color: DSColors.borderLight),
              boxShadow: DSShadows.md,
            ),
            padding: const EdgeInsets.all(DSSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  stat['icon'] as IconData,
                  color: DSColors.primary,
                  size: 28,
                ),
                const SizedBox(height: DSSpacing.xs),
                Text(
                  stat['value'] as String,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: DSColors.primary,
                  ),
                ),
                Text(
                  stat['label'] as String,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DSColors.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
