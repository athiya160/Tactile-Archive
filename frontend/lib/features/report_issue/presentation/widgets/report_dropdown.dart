import 'package:flutter/material.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class ReportDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  const ReportDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: DSSpacing.xs, bottom: 6.0),
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: DSColors.textLight,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: DSSpacing.md),
          decoration: BoxDecoration(
            color: DSColors.borderLight,
            borderRadius: BorderRadius.circular(DSRadius.lg),
            border: Border.all(
              color: DSColors.borderLight.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              hint: Text(
                hint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DSColors.textLight.withValues(alpha: 0.5),
                ),
              ),
              isExpanded: true,
              icon: const Icon(Icons.expand_more, color: DSColors.textLight),
              dropdownColor: DSColors.borderLight,
              items: items,
              onChanged: onChanged,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}
