import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../domain/entities/book.dart';
import '../bloc/home_bloc.dart';
import '../../../../core/tokens/app_tokens.dart';

class BookCard extends StatefulWidget {
  final Book book;

  const BookCard({super.key, required this.book});

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  bool _isHovered = false;

  void _onEnter(PointerEvent details) {
    setState(() => _isHovered = true);
  }

  void _onExit(PointerEvent details) {
    setState(() => _isHovered = false);
  }

  Widget _buildNetworkImage(String url) {
    if (url.isEmpty) {
      return Container(color: AppColors.surfaceContainerHigh);
    }

    final isAsset = url.startsWith('assets/');
    final imageUrl = isAsset ? url : ApiService.resolveImageUrl(url);

    if (isAsset) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            Container(color: AppColors.surfaceContainerHigh),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => Container(color: AppColors.surfaceContainerHigh),
      errorWidget: (context, url, error) => Container(color: AppColors.surfaceContainerHigh),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.book.listingType == ListingType.forRent ? 'For Rent' : (widget.book.listingType == ListingType.donate ? 'Donate' : 'For Sale');
    final condition = widget.book.conditionVerification.isNotEmpty ? widget.book.conditionVerification : 'Good';
    final hasDiscount = widget.book.originalPrice != null && widget.book.originalPrice! > widget.book.price;

    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.push('/book/${widget.book.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? -8 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover Area
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    // Image with hover zoom
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: AnimatedScale(
                        scale: _isHovered ? 1.05 : 1.0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        child: _buildNetworkImage(widget.book.coverUrl),
                      ),
                    ),

                    // Quick View Overlay
                    AnimatedOpacity(
                      opacity: _isHovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Center(
                          child: AnimatedSlide(
                            offset: _isHovered ? Offset.zero : const Offset(0, 0.2),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            child: ElevatedButton.icon(
                              onPressed: () => context.push('/book/${widget.book.id}'),
                              icon: const FaIcon(FontAwesomeIcons.eye, size: 14),
                              label: Text(
                                'Quick View',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Status Badge (Condition)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
                        ),
                        child: Text(
                          condition.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    // Wishlist Button
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () async {
                          if (!ApiService.isLoggedIn) {
                            await requireAuth(
                              context,
                              reason: 'Sign in to save books to your favourites.',
                            );
                            return;
                          }
                          if (context.mounted) {
                            context.read<HomeBloc>().add(HomeFavoriteToggled(widget.book.id));
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.sm,
                          ),
                          child: Center(
                            child: FaIcon(
                              widget.book.isFavorite ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                              size: 14,
                              color: widget.book.isFavorite ? const Color(0xFFE74C3C) : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Info Area
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (status != 'For Sale')
                                Text(
                                  status.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: AppColors.tertiary,
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                              // Rating
                              Row(
                                children: [
                                  const FaIcon(FontAwesomeIcons.solidStar, size: 10, color: AppColors.tertiary),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.book.rating.toStringAsFixed(1),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  if (widget.book.totalReviews > 0)
                                    Text(
                                      ' (${widget.book.totalReviews})',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.book.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      
                      // Price & Dual-action tags (₹ Rupee format)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.book.price == 0
                                ? 'Free'
                                : '₹${widget.book.price.toInt()}${widget.book.listingType == ListingType.forRent ? ' /mo' : ''}',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                '₹${widget.book.originalPrice!.toInt()}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.onSurfaceVariant.withOpacity(0.6),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
