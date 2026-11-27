import 'package:flutter/material.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DSSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: DSColors.textLight, size: 22),
            const SizedBox(width: DSSpacing.md),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: DSColors.textDark,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: DSColors.borderLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
