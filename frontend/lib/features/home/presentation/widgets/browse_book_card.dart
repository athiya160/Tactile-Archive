import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../../core/di/service_locator.dart';
import '../../../book_details/domain/usecases/add_to_cart.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../domain/entities/book.dart';
import '../bloc/home_bloc.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:libri_flow/core/design_system/tokens/ds_colors.dart';

class BrowseBookCard extends StatefulWidget {
  final Book book;

  const BrowseBookCard({super.key, required this.book});

  @override
  State<BrowseBookCard> createState() => _BrowseBookCardState();
}

class _BrowseBookCardState extends State<BrowseBookCard> {
  bool _isHovered = false;

  Widget _buildNetworkImage(String url, {required BoxFit fit}) {
    if (url.isEmpty) {
      return Container(
        color: const Color(0xFFEEEEEE),
        child: const FaIcon(
          FontAwesomeIcons.book,
          size: 36,
          color: Color(0xFF9E9E9E),
        ),
      );
    }
    final isAsset = url.startsWith('assets/');
    final imageUrl = isAsset ? url : ApiService.resolveImageUrl(url);
    if (isAsset) {
      return Image.asset(
        imageUrl,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFEEEEEE),
          child: const FaIcon(
            FontAwesomeIcons.book,
            size: 36,
            color: Color(0xFF9E9E9E),
          ),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      placeholder: (context, url) => Container(color: const Color(0xFFEEEEEE)),
      errorWidget: (context, url, error) => Container(
        color: const Color(0xFFEEEEEE),
        child: const FaIcon(
          FontAwesomeIcons.book,
          size: 36,
          color: Color(0xFF9E9E9E),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDonate = widget.book.listingType == ListingType.donate || widget.book.price == 0;
    final isRent = widget.book.listingType == ListingType.forRent;
    final statusText = isDonate ? 'DONATE' : (isRent ? 'FOR RENT' : 'FOR SALE');
    final badgeColor = isDonate
        ? DSColors.secondaryGreen
        : (isRent ? DSColors.deepForestGreen : const Color(0xFF1E232A));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.push('/book/${widget.book.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.translationValues(0, _isHovered ? -5 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 6,
                child: Container(
                  color: const Color(0xFFEEEEEE),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedScale(
                        scale: _isHovered ? 1.05 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: _buildNetworkImage(
                          widget.book.coverUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: _buildFavoriteButton(context),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: DSColors.deepForestGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by ${widget.book.author}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: DSColors.charcoal,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ISBN: N/A',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF777777),
                              fontFamily: 'Inter',
                            ),
                          ),
                          Row(
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.solidStar,
                                size: 12,
                                color: DSColors.antiqueGold,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.book.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF777777),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            isDonate ? 'Free' : '₹${widget.book.price.toInt()}${isRent ? ' /mo' : ''}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: DSColors.deepForestGreen,
                              fontFamily: 'Inter',
                            ),
                          ),
                          if (widget.book.originalPrice != null &&
                              widget.book.originalPrice! > widget.book.price) ...[
                            const SizedBox(width: 8),
                            Text(
                              '₹${widget.book.originalPrice!.toInt()}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF888888),
                                decoration: TextDecoration.lineThrough,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _isHovered ? 1.0 : 0.0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          transform: Matrix4.translationValues(
                            0,
                            _isHovered ? 0 : 10,
                            0,
                          ),
                          child: _buildActionButton('Add to Cart', true),
                        ),
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

  Widget _buildActionButton(String label, bool isPrimary) {
    return GestureDetector(
      onTap: () async {
        final ok = await requireAuth(
          context,
          reason: 'Sign in to add books to your cart.',
        );
        if (ok && context.mounted) {
          final addToCart = sl<AddToCart>();
          final result = await addToCart(widget.book.id, isPurchase: isPrimary);
          if (context.mounted) {
            result.fold(
              (failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(failure.message),
                    backgroundColor: DSColors.error,
                  ),
                );
              },
              (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Added "$label: ${widget.book.title}" to your cart',
                    ),
                    backgroundColor: DSColors.deepForestGreen,
                  ),
                );
                context.read<CartBloc>().add(CartStarted());
              },
            );
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: DSColors.antiqueGold,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton(BuildContext context) {
    return GestureDetector(
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: FaIcon(
            widget.book.isFavorite
                ? FontAwesomeIcons.solidHeart
                : FontAwesomeIcons.heart,
            size: 16,
            color: widget.book.isFavorite
                ? const Color(0xFFE74C3C)
                : DSColors.charcoal,
          ),
        ),
      ),
    );
  }
}
