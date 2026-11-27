import 'package:flutter/material.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String title;
  final double? progressOverride;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    this.progressOverride,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = progressOverride ?? (currentStep / totalSteps);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STEP ${currentStep.toString().padLeft(2, '0')} OF ${totalSteps.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: DSColors.textLight,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: DSSpacing.xs),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontFamily: 'Noto Serif',
                    fontWeight: FontWeight.bold,
                    color: DSColors.textDark,
                  ),
                ),
              ],
            ),
            Text(
              '${(progress * 100).toInt()}% COMPLETE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: DSColors.textLight,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: DSSpacing.md),
        Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(
            color: DSColors.borderLight,
            borderRadius: BorderRadius.circular(100.0),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: DSColors.primary,
                borderRadius: BorderRadius.circular(100.0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
