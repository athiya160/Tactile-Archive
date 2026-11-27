import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class SettingsInputField extends StatelessWidget {
  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final bool isMultiline;

  const SettingsInputField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            label.toUpperCase(),
            style: IvoryTheme.formFieldLabel.copyWith(
              color: DSColors.textLight,
            ),
          ),
        ),
        const SizedBox(height: DSSpacing.sm),
        TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          maxLines: isMultiline ? 4 : 1,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.2),
          decoration: InputDecoration(
            filled: true,
            fillColor: DSColors.borderLight.withValues(alpha: 0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DSRadius.lg),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DSRadius.lg),
              borderSide: BorderSide(
                color: DSColors.primary.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
