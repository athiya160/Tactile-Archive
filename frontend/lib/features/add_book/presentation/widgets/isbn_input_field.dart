import 'package:flutter/material.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class IsbnInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onFindPressed;
  final VoidCallback onScanPressed;
  final ValueChanged<String> onChanged;
  final bool isLoading;

  const IsbnInputField({
    super.key,
    required this.controller,
    required this.onFindPressed,
    required this.onScanPressed,
    required this.onChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ISBN NUMBER',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: DSColors.textLight,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: DSSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: DSColors.borderLight,
            borderRadius: BorderRadius.circular(DSRadius.lg),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: '978-3-16-148410-0',
                    hintStyle: TextStyle(
                      color: DSColors.border.withValues(alpha: 0.6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: DSSpacing.md,
                      vertical: DSSpacing.md,
                    ),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w500,
                    color: DSColors.textDark,
                  ),
                ),
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(right: DSSpacing.md),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DSColors.primary,
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: onFindPressed,
                  child: Text(
                    'FIND',
                    style: TextStyle(
                      color: DSColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: DSSpacing.sm),
        TextButton.icon(
          onPressed: onScanPressed,
          icon: const Icon(Icons.qr_code_scanner, size: 18),
          label: const Text('SCAN BARCODE'),
          style: TextButton.styleFrom(
            foregroundColor: DSColors.textDark.withValues(alpha: 0.8),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}
