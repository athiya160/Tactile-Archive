import 'package:flutter/material.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class ReportIssueCard extends StatelessWidget {
  final VoidCallback onReportPressed;

  const ReportIssueCard({super.key, required this.onReportPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: DSSpacing.lg,
        vertical: DSSpacing.xl,
      ),
      padding: const EdgeInsets.all(DSSpacing.lg),
      decoration: BoxDecoration(
        color: DSColors.borderLight,
        borderRadius: BorderRadius.circular(DSRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Experiencing an issue?',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: DSColors.textDark),
          ),
          const SizedBox(height: DSSpacing.sm),
          Text(
            'Let us know if you encountered a bug or technical problem with the app.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: DSColors.textLight,
              height: 1.6,
            ),
          ),
          const SizedBox(height: DSSpacing.lg),
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [DSColors.primary, DSColors.primaryHover],
              ),
              borderRadius: BorderRadius.circular(DSRadius.lg),
            ),
            child: ElevatedButton(
              onPressed: onReportPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DSRadius.lg),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.flag_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: DSSpacing.sm),
                  Text(
                    'Report an Issue',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
