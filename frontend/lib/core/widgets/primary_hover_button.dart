import 'package:flutter/material.dart';
import '../tokens/app_tokens.dart';

class PrimaryHoverButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isSecondary;

  const PrimaryHoverButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isSecondary = false,
  });

  @override
  State<PrimaryHoverButton> createState() => _PrimaryHoverButtonState();
}

class _PrimaryHoverButtonState extends State<PrimaryHoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSecondary ? Colors.transparent : AppColors.primary;
    final fgColor = widget.isSecondary ? AppColors.primary : Colors.white;
    final hoverBgColor = widget.isSecondary
        ? AppColors.primary
        : AppColors.primaryContainer;
    final hoverFgColor = Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppTransitions.defaultDuration,
          curve: AppTransitions.defaultCurve,
          transform: Matrix4.translationValues(0, _isHovered ? -2.0 : 0.0, 0),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            color: _isHovered ? hoverBgColor : bgColor,
            borderRadius: BorderRadius.circular(8),
            border: widget.isSecondary
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
            boxShadow: _isHovered ? AppShadows.md : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 18,
                  color: _isHovered ? hoverFgColor : fgColor,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _isHovered ? hoverFgColor : fgColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
