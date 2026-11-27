import 'package:flutter/material.dart';
import '../tokens/app_tokens.dart';
import '../services/api_service.dart';

/// A robust book cover image widget that handles loading, errors,
/// and provides a premium skeleton/fallback experience.
class BookCoverImage extends StatelessWidget {
  final String url;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const BookCoverImage({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(8);

    if (url.isEmpty) {
      return _Placeholder(height: height, width: width, radius: radius);
    }

    final isAsset = url.startsWith('assets/');
    final imageUrl = isAsset ? url : ApiService.resolveImageUrl(url);

    final imageWidget = isAsset
        ? Image.asset(
            imageUrl,
            height: height,
            width: width,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return _Placeholder(height: height, width: width, radius: radius);
            },
          )
        : Image.network(
            imageUrl,
            height: height,
            width: width,
            fit: fit,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _Skeleton(height: height, width: width);
            },
            errorBuilder: (context, error, stackTrace) {
              return _Placeholder(height: height, width: width, radius: radius);
            },
          );

    return ClipRRect(borderRadius: radius, child: imageWidget);
  }
}

// ── Loading Skeleton ────────────────────────────────────────────────────────
class _Skeleton extends StatefulWidget {
  final double? height;
  final double? width;
  const _Skeleton({this.height, this.width});

  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(color: AppColors.surfaceContainerHigh),
      ),
    );
  }
}

// ── Error / Empty Placeholder ───────────────────────────────────────────────
class _Placeholder extends StatelessWidget {
  final double? height;
  final double? width;
  final BorderRadius radius;
  const _Placeholder({this.height, this.width, required this.radius});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: const Color(0xFFF3ECE0),
          border: Border.all(color: const Color(0xFFC5A15A).withValues(alpha: 0.35), width: 1.2),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8F3EA),
              Color(0xFFEFE6D6),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFC5A15A).withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 26,
                color: Color(0xFFC5A15A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'THE ARCHIVE',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                color: Color(0xFF252923),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
