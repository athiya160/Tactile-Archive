import 'package:libri_flow/core/widgets/ivory_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/book_cover_image.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../home/domain/entities/book.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class ReviewPage extends StatefulWidget {
  final Book book;
  final String orderId;
  const ReviewPage({super.key, required this.book, required this.orderId});
  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage>
    with SingleTickerProviderStateMixin {
  double _rating = 5.0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  final List<String> _ratingLabels = [
    'Hated it',
    'Disliked it',
    'It\'s OK',
    'Liked it',
    'Loved it',
  ];
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _commentController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onStarTapped(double ratingValue) {
    setState(() {
      _rating = ratingValue;
    });
    _animController.forward().then((_) => _animController.reverse());
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please write a comment for your review.'),
          backgroundColor: DSColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DSRadius.lg),
          ),
        ),
      );
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    try {
      final orderIdInt = int.tryParse(widget.orderId) ?? 0;
      final bookIdInt = int.tryParse(widget.book.id) ?? 0;
      await sl<ApiClient>().postJson(
        '/reviews',
        body: {
          'book_id': bookIdInt,
          'order_id': orderIdInt,
          'rating': _rating,
          'comment': _commentController.text.trim(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Review submitted successfully!'),
            backgroundColor: DSColors.deepForestGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DSRadius.lg),
            ),
          ),
        );
        context.pop(true);
        // Return success flag to trigger refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: $e'),
            backgroundColor: DSColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DSRadius.lg),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int labelIndex = (_rating - 1).round().clamp(0, 4);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        return IvoryScaffold(
          title: 'Rate this Book',
          showAppBar: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: DSColors.textDark),
            onPressed: () => context.pop(),
          ),
          body: SingleChildScrollView(
            physics: isDesktop
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              24,
              100 + MediaQuery.of(context).padding.top,
              24,
              40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book Details Header Card
                Container(
                  padding: const EdgeInsets.all(DSSpacing.md),
                  decoration: BoxDecoration(
                    color: DSColors.border,
                    borderRadius: BorderRadius.circular(DSRadius.xl),
                    border: Border.all(color: DSColors.borderLight, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 84,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(DSRadius.sm),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(DSRadius.sm),
                          child: BookCoverImage(
                            url: widget.book.coverUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: DSSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.book.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: DSColors.primary,
                                    height: 1.2,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'by ${widget.book.author}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: DSColors.textLight),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DSSpacing.xl),

                // Star Rating Section
                Text(
                  'YOUR RATING',
                  style: IvoryTheme.smallCapsLabel.copyWith(
                    color: DSColors.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: DSSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: DSSpacing.lg,
                    horizontal: DSSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: DSColors.border,
                    borderRadius: BorderRadius.circular(DSRadius.xl),
                    border: Border.all(color: DSColors.borderLight, width: 1),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starVal = index + 1.0;
                          final isSelected = _rating >= starVal;
                          return GestureDetector(
                            onTap: () => _onStarTapped(starVal),
                            child: ScaleTransition(
                              scale: _rating == starVal
                                  ? _scaleAnimation
                                  : const AlwaysStoppedAnimation(1.0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                ),
                                child: Icon(
                                  isSelected
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: isSelected
                                      ? DSColors.antiqueGold
                                      : DSColors.borderLight,
                                  size: 44,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: DSSpacing.sm),
                      Text(
                        _ratingLabels[labelIndex].toUpperCase(),
                        style: IvoryTheme.statusLabel.copyWith(
                          color: DSColors.antiqueGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DSSpacing.xl),

                // Written Review Section
                Text(
                  'WRITE A REVIEW',
                  style: IvoryTheme.smallCapsLabel.copyWith(
                    color: DSColors.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: DSSpacing.sm),
                TextField(
                  controller: _commentController,
                  minLines: 4,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText:
                        'Share your thoughts about the book. What did you like or dislike? How was the physical condition?',
                    hintStyle: TextStyle(
                      color: DSColors.textLight.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: DSColors.border,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DSRadius.xl),
                      borderSide: const BorderSide(
                        color: DSColors.borderLight,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DSRadius.xl),
                      borderSide: const BorderSide(
                        color: DSColors.borderLight,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DSRadius.xl),
                      borderSide: const BorderSide(
                        color: DSColors.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(DSSpacing.md),
                  ),
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: DSSpacing.xxl),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DSColors.deepForestGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(
                        0xFF061B0E,
                      ).withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DSRadius.xl),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'SUBMIT REVIEW',
                            style: IvoryTheme.smallCapsLabel.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
