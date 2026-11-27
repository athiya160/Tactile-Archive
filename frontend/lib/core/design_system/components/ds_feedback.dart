import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens/ds_colors.dart';
import '../tokens/ds_radius.dart';
import '../tokens/ds_shadows.dart';
import 'ds_buttons.dart';

class DSSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: DSColors.paperWhite,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        backgroundColor: isError ? DSColors.error : DSColors.deepForestGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class DSEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const DSEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: DSColors.warmIvory,
                shape: BoxShape.circle,
                border: Border.all(color: DSColors.softBorder),
              ),
              child: Icon(icon, size: 52, color: DSColors.secondaryGreen),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: DSColors.deepForestGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: DSColors.textLight,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28),
              DSButton.primary(
                text: actionLabel!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DSErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  const DSErrorState({
    super.key,
    this.title = 'Unable to Load Content',
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try Again',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DSColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: DSColors.error.withValues(alpha: 0.25)),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: DSColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: DSColors.charcoal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: DSColors.textLight,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              DSButton.secondary(
                text: retryLabel,
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DSDialog {
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required String content,
    required String primaryActionLabel,
    required VoidCallback onPrimaryAction,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
    bool isDestructive = false,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: DSColors.paperWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DSRadius.card),
            side: const BorderSide(color: DSColors.softBorder),
          ),
          title: Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: DSColors.deepForestGreen,
            ),
          ),
          content: Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: DSColors.charcoal,
              height: 1.5,
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          actions: [
            if (secondaryActionLabel != null)
              DSButton.secondary(
                text: secondaryActionLabel,
                height: 42,
                onPressed: () {
                  if (onSecondaryAction != null) {
                    onSecondaryAction();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            DSButton(
              text: primaryActionLabel,
              height: 42,
              variant: isDestructive ? DSButtonVariant.terracotta : DSButtonVariant.primary,
              onPressed: onPrimaryAction,
            ),
          ],
        );
      },
    );
  }
}

class DSBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: DSColors.paperWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: DSShadows.lg,
            border: const Border(top: BorderSide(color: DSColors.softBorder)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom +
                16,
            left: 20,
            right: 20,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottom sheet drag handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DSColors.softBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (title != null) ...[
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: DSColors.deepForestGreen,
                  ),
                ),
                const SizedBox(height: 12),
              ] else
                const SizedBox(height: 12),
              child,
            ],
          ),
        );
      },
    );
  }
}
