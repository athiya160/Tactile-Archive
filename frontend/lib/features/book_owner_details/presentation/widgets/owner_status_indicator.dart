import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class OwnerStatusIndicator extends StatelessWidget {
  const OwnerStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.md,
        vertical: DSSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFECF3EE).withValues(alpha: 0.5), // emerald-50/50
        borderRadius: BorderRadius.circular(100.0),
        border: Border.all(
          color: const Color(
            0xFFD1E4D8,
          ).withValues(alpha: 0.5), // emerald-100/50
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            size: 14,
            color: Color(0xFF064E3B), // emerald-800
          ),
          const SizedBox(width: 8),
          Text(
            'LISTING ACTIVE & VERIFIED',
            style: IvoryTheme.statusLabel.copyWith(
              color: const Color(0xFF064E3B), // emerald-800
            ),
          ),
        ],
      ),
    );
  }
}
