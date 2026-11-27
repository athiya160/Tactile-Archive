import 'package:flutter/material.dart';
import '../tokens/ds_colors.dart';
import '../tokens/ds_radius.dart';
import '../tokens/ds_shadows.dart';

enum CustomButtonVariant { primary, secondary, gold }

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final CustomButtonVariant variant;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = CustomButtonVariant.primary,
    this.icon,
  });

  factory CustomButton.primary({
    Key? key,
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
  }) => CustomButton(
    key: key,
    text: text,
    onPressed: onPressed,
    variant: CustomButtonVariant.primary,
    icon: icon,
  );

  factory CustomButton.secondary({
    Key? key,
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
  }) => CustomButton(
    key: key,
    text: text,
    onPressed: onPressed,
    variant: CustomButtonVariant.secondary,
    icon: icon,
  );

  factory CustomButton.gold({
    Key? key,
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
  }) => CustomButton(
    key: key,
    text: text,
    onPressed: onPressed,
    variant: CustomButtonVariant.gold,
    icon: icon,
  );

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Border? border;

    switch (widget.variant) {
      case CustomButtonVariant.primary:
        bgColor = _isHovered ? DSColors.primaryHover : DSColors.primary;
        textColor = DSColors.textInverse;
        break;
      case CustomButtonVariant.secondary:
        bgColor = _isHovered ? DSColors.primary : Colors.transparent;
        textColor = _isHovered ? DSColors.textInverse : DSColors.primary;
        border = Border.all(color: DSColors.primary, width: 2);
        break;
      case CustomButtonVariant.gold:
        bgColor = _isHovered ? DSColors.secondaryHover : DSColors.secondary;
        textColor = DSColors.textInverse;
        break;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? -2.0 : 0.0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(DSRadius.md),
            border: border,
            boxShadow: _isHovered ? DSShadows.md : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: textColor, size: 16),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
