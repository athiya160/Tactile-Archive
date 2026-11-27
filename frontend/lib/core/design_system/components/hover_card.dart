import 'package:flutter/material.dart';
import '../tokens/ds_colors.dart';
import '../tokens/ds_radius.dart';
import '../tokens/ds_shadows.dart';

/// Tactile 3D Hover & Touch Card
/// - On Desktop: Subtle perspective lift and layered shadow on hover.
/// - On Mobile: Lightweight touch elevation and tactile compression on press.
/// - Accessibility: Strictly respects reduced-motion preferences.
class HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color backgroundColor;
  final Border? border;
  final Border? hoverBorder;
  final double translateY;
  final double scale;
  final Clip clipBehavior;
  final bool enablePerspective;

  const HoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = EdgeInsets.zero,
    this.borderRadius = DSRadius.card,
    this.backgroundColor = DSColors.surface,
    this.border,
    this.hoverBorder,
    this.translateY = -5.0,
    this.scale = 1.0,
    this.clipBehavior = Clip.none,
    this.enablePerspective = true,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;
  bool _isPressed = false;
  double _rotateX = 0.0;
  double _rotateY = 0.0;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    Matrix4 transform = Matrix4.identity();
    if (!reduceMotion) {
      if (_isPressed) {
        transform = Matrix4.diagonal3Values(0.985, 0.985, 1.0);
      } else if (_isHovered) {
        if (widget.enablePerspective && (_rotateX != 0 || _rotateY != 0)) {
          transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // subtle perspective depth
            ..rotateX(_rotateX)
            ..rotateY(_rotateY)
            ..multiply(Matrix4.translationValues(0.0, widget.translateY, 0.0));
        } else {
          transform = Matrix4.translationValues(0.0, widget.translateY, 0.0);
        }
      }
    }

    final effectiveBorder = _isHovered && widget.hoverBorder != null
        ? widget.hoverBorder
        : (widget.border ?? Border.all(color: DSColors.softBorder));

    final effectiveShadow = _isPressed
        ? DSShadows.sm
        : (_isHovered ? DSShadows.bookCardHover : DSShadows.bookCard);

    Widget content = AnimatedContainer(
      duration: Duration(milliseconds: reduceMotion ? 0 : 200),
      curve: Curves.easeOutCubic,
      transform: transform,
      transformAlignment: Alignment.center,
      padding: widget.padding,
      clipBehavior: widget.clipBehavior,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: effectiveBorder,
        boxShadow: effectiveShadow,
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      content = Listener(
        onPointerDown: (_) => setState(() => _isPressed = true),
        onPointerUp: (_) => setState(() => _isPressed = false),
        onPointerCancel: (_) => setState(() => _isPressed = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: content,
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) {
        setState(() {
          _isHovered = false;
          _rotateX = 0.0;
          _rotateY = 0.0;
        });
      },
      onHover: (event) {
        if (!widget.enablePerspective || reduceMotion) return;
        final RenderBox? box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final size = box.size;
        final local = event.localPosition;
        final dx = (local.dx / size.width - 0.5) * 2; // -1.0 to 1.0
        final dy = (local.dy / size.height - 0.5) * 2;
        setState(() {
          _rotateX = -dy * 0.035; // max ~2 degrees tilt
          _rotateY = dx * 0.035;
        });
      },
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: content,
    );
  }
}
