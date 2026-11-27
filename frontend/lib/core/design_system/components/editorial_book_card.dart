import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens/ds_colors.dart';
import '../tokens/ds_radius.dart';
import 'hover_card.dart';
import 'book_image_container.dart';
import 'ds_indicators.dart';

/// Luxury Editorial 3D Book Card
/// Provides:
/// - Tactile cover with spine lighting
/// - Playfair serif headline + Inter author
/// - Condition badge & Availability pill
/// - Formatted INR price (₹)
/// - Rating star only when rating > 0
/// - Heart favorite toggle micro-interaction
/// - Subtle 3D tilt on desktop and tactile press on mobile
class EditorialBookCard extends StatelessWidget {
  final String title;
  final String author;
  final double price;
  final String? imageUrl;
  final String? condition;
  final String? availability; // e.g. "Buy", "Rent", "Borrow"
  final String? providerName;
  final double? rating;
  final int? reviewCount;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onAddToCart;
  final double width;
  final double? imageHeight;

  const EditorialBookCard({
    super.key,
    required this.title,
    required this.author,
    required this.price,
    this.imageUrl,
    this.condition,
    this.availability,
    this.providerName,
    this.rating,
    this.reviewCount,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteToggle,
    this.onAddToCart,
    this.width = 190.0,
    this.imageHeight = 175.0,
  });

  @override
  Widget build(BuildContext context) {
    return HoverCard(
      onTap: onTap,
      borderRadius: DSRadius.card,
      backgroundColor: DSColors.paperWhite,
      padding: const EdgeInsets.all(12.0),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cover Image with spine gradient & badges
            BookImageContainer(
              imageUrl: imageUrl,
              width: width,
              height: imageHeight,
              badge: condition != null && condition!.isNotEmpty
                  ? DSBadge(
                      text: condition!,
                      backgroundColor: _getConditionColor(condition!),
                      textColor: DSColors.paperWhite,
                    )
                  : (availability != null && availability!.isNotEmpty
                      ? DSBadge(
                          text: availability!,
                          backgroundColor: DSColors.deepForestGreen,
                          textColor: DSColors.paperWhite,
                        )
                      : null),
              favoriteButton: onFavoriteToggle != null
                  ? Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onFavoriteToggle,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: DSColors.paperWhite.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
                            size: 16,
                            color: isFavorite ? DSColors.mutedTerracotta : DSColors.textMuted,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),

            // Availability pill + Rating row
            Row(
              children: [
                if (availability != null && availability!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: DSColors.warmIvory,
                      borderRadius: BorderRadius.circular(DSRadius.sm),
                      border: Border.all(color: DSColors.softBorder),
                    ),
                    child: Text(
                      availability!.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: DSColors.secondaryGreen,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
                if (rating != null && rating! > 0) ...[
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: DSColors.warmGold,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    rating!.toStringAsFixed(1),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: DSColors.charcoal,
                    ),
                  ),
                  if (reviewCount != null && reviewCount! > 0)
                    Text(
                      ' ($reviewCount)',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: DSColors.textMuted,
                      ),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Book Title in Playfair Display
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: DSColors.charcoal,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),

            // Author in Inter
            Text(
              author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: DSColors.textLight,
              ),
            ),

            if (providerName != null && providerName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.storefront_outlined,
                    size: 12,
                    color: DSColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      providerName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: DSColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 10),

            // Price in INR + Cart micro-action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  price <= 0 ? 'Free / Borrow' : '₹${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: DSColors.deepForestGreen,
                  ),
                ),
                if (onAddToCart != null)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onAddToCart,
                      borderRadius: BorderRadius.circular(DSRadius.sm),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: DSColors.warmIvory,
                          borderRadius: BorderRadius.circular(DSRadius.sm),
                          border: Border.all(color: DSColors.softBorder),
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          size: 16,
                          color: DSColors.deepForestGreen,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getConditionColor(String cond) {
    final lower = cond.toLowerCase();
    if (lower.contains('new') || lower.contains('mint')) {
      return DSColors.secondaryGreen;
    } else if (lower.contains('good') || lower.contains('fine')) {
      return DSColors.deepForestGreen;
    } else if (lower.contains('fair') || lower.contains('used')) {
      return DSColors.mutedTerracotta;
    }
    return DSColors.deepForestGreen;
  }
}
