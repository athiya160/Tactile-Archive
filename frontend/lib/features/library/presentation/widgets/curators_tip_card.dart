import 'package:flutter/material.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class CuratorsTipCard extends StatelessWidget {
  const CuratorsTipCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.lg),
      decoration: BoxDecoration(
        color: DSColors.primary,
        borderRadius: BorderRadius.circular(DSRadius.lg),
        boxShadow: DSShadows.md,
        border: Border.all(color: DSColors.primary.withValues(alpha: 0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Curator's Tip",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: DSColors.textInverse,
                ),
              ),
              const SizedBox(height: DSSpacing.sm),
              Text(
                '"A library is one of the necessities of life." High-resolution photos increase your archive rank and help maintain the tactile quality of our digital records.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DSColors.textInverse.withValues(alpha: 0.8),
                  height: 1.6,
                ),
              ),
            ],
          ),
          Positioned(
            right: -24,
            bottom: -32,
            child: Opacity(
              opacity: 0.1,
              child: Icon(
                Icons.history_edu,
                size: 128,
                color: DSColors.textInverse,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
