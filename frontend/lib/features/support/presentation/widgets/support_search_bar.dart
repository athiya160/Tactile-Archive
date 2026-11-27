import 'package:flutter/material.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class SupportSearchBar extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final String? initialValue;

  const SupportSearchBar({super.key, this.onChanged, this.initialValue});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: DSColors.borderLight,
        borderRadius: BorderRadius.circular(
          DSRadius.xl * 2,
        ), // Organic/Held style
      ),
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: DSColors.textLight),
          const SizedBox(width: DSSpacing.sm),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              controller: initialValue != null
                  ? TextEditingController(text: initialValue)
                  : null,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: DSColors.textDark),
              decoration: InputDecoration(
                hintText: 'Search topics...',
                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: DSColors.textLight.withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
