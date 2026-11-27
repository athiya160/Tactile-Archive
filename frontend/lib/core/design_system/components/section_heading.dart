import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens/ds_colors.dart';

/// Editorial Section Heading
/// Features:
/// - Optional uppercase eyebrow tag (e.g., "CURATED SELECTION")
/// - Playfair Display serif headline
/// - Optional subtitle for context
/// - Trailing action button (e.g., "Explore All →")
class SectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? eyebrow;
  final String? actionText;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const SectionHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.actionText,
    this.onAction,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null && eyebrow!.isNotEmpty) ...[
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 2,
                        color: DSColors.mutedTerracotta,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        eyebrow!.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: DSColors.mutedTerracotta,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: DSColors.deepForestGreen,
                    height: 1.2,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: DSColors.textLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(width: 12),
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionText!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DSColors.secondaryGreen,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: DSColors.secondaryGreen,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
