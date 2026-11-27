import 'package:flutter/material.dart';
import '../tokens/ds_colors.dart';
import '../tokens/ds_radius.dart';

/// Tactile Book Image Container
/// Features:
/// - Consistent 2:3 book proportion aspect ratio
/// - Left spine gradient overlay creating tactile 3D hardcover depth
/// - Clean paper-white fallback when image is unavailable
/// - Badge overlay support
class BookImageContainer extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final double aspectRatio;
  final Widget? badge;
  final Widget? favoriteButton;
  final BorderRadius? borderRadius;

  const BookImageContainer({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.aspectRatio = 2 / 3,
    this.badge,
    this.favoriteButton,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(DSRadius.md);

    Widget imageWidget;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      final isAsset = imageUrl!.startsWith('assets/');
      if (isAsset) {
        imageWidget = Image.asset(
          imageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      } else {
        imageWidget = Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: DSColors.softSurface,
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(DSColors.antiqueGold),
                  ),
                ),
              ),
            );
          },
        );
      }
    } else {
      imageWidget = _buildPlaceholder();
    }

    Widget content = Stack(
      children: [
        // Base book cover image
        Positioned.fill(child: imageWidget),

        // Spine depth gradient on left edge (subtle 3D hardcover effect)
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 14,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.22),
                  Colors.black.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),

        // Subtle right edge highlight (page turn sheen)
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.18),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),

        // Optional top-left badge (Condition / Availability)
        if (badge != null)
          Positioned(
            top: 8,
            left: 8,
            child: badge!,
          ),

        // Optional top-right favorite action
        if (favoriteButton != null)
          Positioned(
            top: 6,
            right: 6,
            child: favoriteButton!,
          ),
      ],
    );

    final container = Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        color: DSColors.softSurface,
        border: Border.all(color: DSColors.softBorder.withValues(alpha: 0.8), width: 1),
        boxShadow: [
          BoxShadow(
            color: DSColors.charcoal.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: content,
    );

    if (height != null) {
      return SizedBox(
        width: width ?? (height! * aspectRatio),
        height: height,
        child: container,
      );
    }

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: container,
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3ECE0),
        border: Border.all(color: DSColors.antiqueGold.withValues(alpha: 0.35), width: 1.5),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8F3EA),
            Color(0xFFEFE6D6),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DSColors.antiqueGold.withValues(alpha: 0.15),
                  border: Border.all(color: DSColors.antiqueGold.withValues(alpha: 0.3), width: 1),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  size: 26,
                  color: DSColors.antiqueGold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'THE TACTILE ARCHIVE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8.5,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: DSColors.charcoal.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Archival Edition',
                style: TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: DSColors.charcoal.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
