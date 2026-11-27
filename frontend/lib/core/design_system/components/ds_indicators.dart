import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens/ds_colors.dart';
import '../tokens/ds_radius.dart';

enum DSBadgeVariant { primary, secondary, success, warning, error, terracotta, outline }

class DSBadge extends StatelessWidget {
  final String text;
  final DSBadgeVariant variant;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const DSBadge({
    super.key,
    required this.text,
    this.variant = DSBadgeVariant.primary,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;

    switch (variant) {
      case DSBadgeVariant.primary:
        bg = DSColors.deepForestGreen;
        fg = DSColors.paperWhite;
        break;
      case DSBadgeVariant.secondary:
        bg = DSColors.secondaryGreen;
        fg = DSColors.paperWhite;
        break;
      case DSBadgeVariant.success:
        bg = DSColors.secondaryGreen.withValues(alpha: 0.15);
        fg = DSColors.secondaryGreen;
        border = Border.all(color: DSColors.secondaryGreen.withValues(alpha: 0.3));
        break;
      case DSBadgeVariant.warning:
        bg = DSColors.warmGold.withValues(alpha: 0.15);
        fg = DSColors.warmGold;
        border = Border.all(color: DSColors.warmGold.withValues(alpha: 0.3));
        break;
      case DSBadgeVariant.error:
        bg = DSColors.error.withValues(alpha: 0.12);
        fg = DSColors.error;
        border = Border.all(color: DSColors.error.withValues(alpha: 0.3));
        break;
      case DSBadgeVariant.terracotta:
        bg = DSColors.mutedTerracotta;
        fg = DSColors.paperWhite;
        break;
      case DSBadgeVariant.outline:
        bg = Colors.transparent;
        fg = DSColors.deepForestGreen;
        border = Border.all(color: DSColors.softBorder, width: 1.2);
        break;
    }

    if (backgroundColor != null) bg = backgroundColor!;
    if (textColor != null) fg = textColor!;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class DSChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;
  final IconData? icon;
  final int? count;

  const DSChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onSelected,
    this.icon,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return AnimatedContainer(
      duration: Duration(milliseconds: reduceMotion ? 0 : 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isSelected ? DSColors.deepForestGreen : DSColors.warmIvory,
        borderRadius: BorderRadius.circular(DSRadius.pill),
        border: Border.all(
          color: isSelected ? DSColors.deepForestGreen : DSColors.softBorder,
          width: 1.2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: DSColors.deepForestGreen.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelected != null ? () => onSelected!(!isSelected) : null,
          borderRadius: BorderRadius.circular(DSRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected ? DSColors.paperWhite : DSColors.secondaryGreen,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? DSColors.paperWhite : DSColors.charcoal,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? DSColors.paperWhite.withValues(alpha: 0.25)
                          : DSColors.softBorder,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? DSColors.paperWhite : DSColors.charcoal,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DSLoadingWidget extends StatelessWidget {
  final String? message;

  const DSLoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              valueColor: AlwaysStoppedAnimation<Color>(DSColors.deepForestGreen),
            ),
          ),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              message!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: DSColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
