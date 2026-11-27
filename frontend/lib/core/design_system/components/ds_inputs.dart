import 'package:flutter/material.dart';
import '../tokens/ds_colors.dart';
import '../tokens/ds_radius.dart';

class DSTextField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final int maxLines;
  final bool autofocus;

  const DSTextField({
    super.key,
    this.labelText,
    this.hintText,
    this.helperText,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: DSColors.deepForestGreen,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          enabled: enabled,
          maxLines: maxLines,
          autofocus: autofocus,
          cursorColor: DSColors.deepForestGreen,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: DSColors.charcoal,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? DSColors.paperWhite : DSColors.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: DSColors.textMuted,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DSRadius.md),
              borderSide: const BorderSide(color: DSColors.softBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DSRadius.md),
              borderSide: const BorderSide(color: DSColors.softBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DSRadius.md),
              borderSide: const BorderSide(
                color: DSColors.deepForestGreen,
                width: 1.8,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DSRadius.md),
              borderSide: const BorderSide(color: DSColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DSRadius.md),
              borderSide: const BorderSide(color: DSColors.error, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}

class DSSearchBar extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onScanTap;
  final VoidCallback? onClear;
  final bool autofocus;

  const DSSearchBar({
    super.key,
    this.hintText = 'Search books, authors, courses, ISBN...',
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onScanTap,
    this.onClear,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DSColors.paperWhite,
        borderRadius: BorderRadius.circular(DSRadius.pill),
        border: Border.all(color: DSColors.softBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: DSColors.charcoal.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        autofocus: autofocus,
        cursorColor: DSColors.deepForestGreen,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: DSColors.charcoal,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: DSColors.textMuted,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: DSColors.secondaryGreen,
            size: 22,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onClear != null && (controller?.text.isNotEmpty ?? false))
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: DSColors.textMuted,
                  onPressed: onClear,
                ),
              if (onScanTap != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: InkWell(
                    onTap: onScanTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: DSColors.warmIvory,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: DSColors.softBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.camera_alt_outlined,
                            size: 14,
                            color: DSColors.deepForestGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'SCAN',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 0.8,
                              color: DSColors.deepForestGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 18,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
