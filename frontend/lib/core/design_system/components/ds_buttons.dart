import 'package:flutter/material.dart';
import '../tokens/ds_colors.dart';
import '../tokens/ds_radius.dart';
import '../tokens/ds_shadows.dart';

enum DSButtonVariant { primary, secondary, terracotta, gold, ghost }

class DSButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final DSButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final double? width;
  final EdgeInsetsGeometry padding;

  const DSButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.variant = DSButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48.0,
    this.width,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
  });

  const DSButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48.0,
    this.width,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
  }) : variant = DSButtonVariant.primary;

  const DSButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48.0,
    this.width,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
  }) : variant = DSButtonVariant.secondary;

  const DSButton.terracotta({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48.0,
    this.width,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
  }) : variant = DSButtonVariant.terracotta;

  const DSButton.gold({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48.0,
    this.width,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
  }) : variant = DSButtonVariant.gold;

  const DSButton.ghost({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48.0,
    this.width,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
  }) : variant = DSButtonVariant.ghost;

  @override
  State<DSButton> createState() => _DSButtonState();
}

class _DSButtonState extends State<DSButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    Color hoverBgColor;
    Color hoverFgColor;
    Border? border;

    switch (widget.variant) {
      case DSButtonVariant.primary:
        bgColor = DSColors.deepForestGreen;
        fgColor = DSColors.paperWhite;
        hoverBgColor = DSColors.forestGreenHover;
        hoverFgColor = DSColors.paperWhite;
        border = null;
        break;
      case DSButtonVariant.secondary:
        bgColor = Colors.transparent;
        fgColor = DSColors.deepForestGreen;
        hoverBgColor = DSColors.deepForestGreen.withValues(alpha: 0.05);
        hoverFgColor = DSColors.deepForestGreen;
        border = Border.all(color: DSColors.softBorder, width: 1.4);
        break;
      case DSButtonVariant.terracotta:
        bgColor = DSColors.mutedTerracotta;
        fgColor = DSColors.paperWhite;
        hoverBgColor = DSColors.terracottaHover;
        hoverFgColor = DSColors.paperWhite;
        border = null;
        break;
      case DSButtonVariant.gold:
        bgColor = DSColors.warmGold;
        fgColor = DSColors.paperWhite;
        hoverBgColor = DSColors.secondaryHover;
        hoverFgColor = DSColors.paperWhite;
        border = null;
        break;
      case DSButtonVariant.ghost:
        bgColor = Colors.transparent;
        fgColor = DSColors.deepForestGreen;
        hoverBgColor = DSColors.deepForestGreen.withValues(alpha: 0.06);
        hoverFgColor = DSColors.deepForestGreen;
        border = null;
        break;
    }

    final bool isDisabled = widget.onPressed == null || widget.isLoading;
    if (isDisabled && !widget.isLoading) {
      bgColor = DSColors.softBorder.withValues(alpha: 0.6);
      fgColor = DSColors.textMuted;
      border = null;
    }

    final bool reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    Widget buttonContent = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _isHovered ? hoverFgColor : fgColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (widget.icon != null) ...[
          Icon(
            widget.icon,
            size: 18,
            color: _isHovered ? hoverFgColor : fgColor,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.text,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: _isHovered ? hoverFgColor : fgColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );

    final scale = _isPressed && !isDisabled ? 0.98 : 1.0;
    final translateY = (_isHovered && !isDisabled && !_isPressed) ? -1.5 : 0.0;
    final transform = Matrix4.diagonal3Values(scale, scale, 1.0)
      ..multiply(Matrix4.translationValues(0.0, translateY, 0.0));

    Widget container = AnimatedContainer(
      duration: Duration(milliseconds: reduceMotion ? 0 : 150),
      curve: Curves.easeOutCubic,
      transform: transform,
      height: widget.height,
      width: widget.isFullWidth ? double.infinity : widget.width,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: _isHovered ? hoverBgColor : bgColor,
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: border,
        boxShadow: (_isHovered && !isDisabled && widget.variant == DSButtonVariant.primary)
            ? DSShadows.sm
            : [],
      ),
      child: Center(
        child: buttonContent,
      ),
    );

    if (isDisabled) {
      return container;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Listener(
        onPointerDown: (_) => setState(() => _isPressed = true),
        onPointerUp: (_) => setState(() => _isPressed = false),
        onPointerCancel: (_) => setState(() => _isPressed = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          behavior: HitTestBehavior.opaque,
          child: container,
        ),
      ),
    );
  }
}
