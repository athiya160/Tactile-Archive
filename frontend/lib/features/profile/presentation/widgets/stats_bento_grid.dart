import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class StatsBentoGrid extends StatelessWidget {
  final int borrowedCount;
  final int sharedCount;

  const StatsBentoGrid({
    super.key,
    required this.borrowedCount,
    required this.sharedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BentoCard(
            icon: Icons.auto_stories_outlined,
            value: borrowedCount.toString(),
            label: 'Books Borrowed',
            onTap: () {
              context.go('/library?tab=0');
            },
          ),
        ),
        const SizedBox(width: DSSpacing.md),
        Expanded(
          child: _BentoCard(
            icon: Icons.volunteer_activism_outlined,
            value: sharedCount.toString(),
            label: 'Books Shared',
            onTap: () {
              context.go('/library?tab=1');
            },
          ),
        ),
      ],
    );
  }
}

class _BentoCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _BentoCard({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20.0), // p-5 in code.html
        decoration: BoxDecoration(
          color: DSColors.surface,
          borderRadius: BorderRadius.circular(DSRadius.lg),
          border: Border.all(
            color: DSColors.borderLight.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: DSColors.border, size: 24),
            const SizedBox(height: DSSpacing.md),
            Text(
              value,
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: DSColors.primary,
                fontSize: 30.0, // Match text-3xl
                letterSpacing: -0.8, // tracking-tighter
              ),
            ),
            const SizedBox(height: DSSpacing.xs),
            Text(
              label.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 10,
                color: DSColors.border,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
