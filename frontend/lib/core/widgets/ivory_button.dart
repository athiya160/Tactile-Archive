import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../tokens/app_tokens.dart';

class IvoryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isGhost;
  final TextStyle? textStyle;
  final Color? backgroundColor;

  const IvoryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
    this.isGhost = false,
    this.textStyle,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isGhost) {
      return Opacity(
        opacity: onPressed == null ? 0.3 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              highlightColor: AppColors.surfaceContainerLow,
              splashColor: AppColors.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style:
                      textStyle ??
                      IvoryTheme.buttonLabel.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (!isPrimary) {
      return Opacity(
        opacity: onPressed == null ? 0.3 : 1.0,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.onSurface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
          child: Text(
            label.toUpperCase(),
            style: textStyle ?? Theme.of(context).textTheme.labelLarge,
          ),
        ),
      );
    }

    return Opacity(
      opacity: onPressed == null ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.ambient,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Text(
                label.toUpperCase(),
                textAlign: TextAlign.center,
                style: textStyle ?? IvoryTheme.buttonLabelWideSpacing,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
