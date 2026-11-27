import 'package:flutter/material.dart';
import '../tokens/ds_colors.dart';
import '../tokens/ds_radius.dart';

/// Lightweight, 60-FPS Shimmer Loading Skeleton
/// Avoids heavy shaders and respects reduced-motion accessibility settings.
class DSSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const DSSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  const DSSkeleton.circle({
    super.key,
    required double size,
  }) : width = size,
       height = size,
       borderRadius = 999.0;

  @override
  State<DSSkeleton> createState() => _DSSkeletonState();
}

class _DSSkeletonState extends State<DSSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: DSColors.softSurface,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: DSColors.softBorder.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Loading Skeleton matching EditorialBookCard dimensions
class DSSkeletonBookCard extends StatelessWidget {
  final double width;
  final double imageHeight;

  const DSSkeletonBookCard({
    super.key,
    this.width = 190.0,
    this.imageHeight = 175.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DSColors.paperWhite,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cover skeleton
          SizedBox(
            width: double.infinity,
            height: imageHeight,
            child: DSSkeleton(
              width: double.infinity,
              height: double.infinity,
              borderRadius: DSRadius.md,
            ),
          ),
          const SizedBox(height: 10),
          // Badge skeleton
          const DSSkeleton(width: 60, height: 16, borderRadius: 4),
          const SizedBox(height: 6),
          // Title skeleton
          const DSSkeleton(width: 140, height: 16, borderRadius: 4),
          const SizedBox(height: 4),
          // Author skeleton
          const DSSkeleton(width: 90, height: 12, borderRadius: 4),
          const SizedBox(height: 10),
          // Price skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              DSSkeleton(width: 50, height: 16, borderRadius: 4),
              DSSkeleton(width: 28, height: 28, borderRadius: 6),
            ],
          ),
        ],
      ),
    );
  }
}
