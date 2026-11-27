import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../home/domain/entities/book.dart';
import 'package:libri_flow/core/design_system/tokens/ds_colors.dart';

class BookInfoSectionV2 extends StatefulWidget {
  final Book book;

  const BookInfoSectionV2({super.key, required this.book});

  @override
  State<BookInfoSectionV2> createState() => _BookInfoSectionState();
}

class _BookInfoSectionState extends State<BookInfoSectionV2> {
  bool _isDescriptionExpanded = false;
  bool _isWishlisted = false;

  @override
  Widget build(BuildContext context) {
    final pagesStr = (widget.book.pages != null && widget.book.pages!.isNotEmpty)
        ? (widget.book.pages!.contains('page') ? widget.book.pages! : '${widget.book.pages} pages')
        : 'Not specified';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. EYEBROW TAGS (Category + Stock Availability)
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFCEEAD6)),
              ),
              child: Text(
                (widget.book.category.isNotEmpty ? widget.book.category : 'Fiction').toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: DSColors.secondaryGreen,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            if (widget.book.isAvailable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCEEAD6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 12, color: DSColors.secondaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      widget.book.stock > 1 ? 'IN STOCK (${widget.book.stock})' : 'IN STOCK',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: DSColors.secondaryGreen,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFDC2626)),
                    const SizedBox(width: 4),
                    Text(
                      widget.book.approvalStatus != 'approved' ? 'UNDER REVIEW' : 'OUT OF STOCK',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFDC2626),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // 2. BOOK TITLE
        Text(
          widget.book.title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            height: 1.2,
            fontWeight: FontWeight.bold,
            color: DSColors.deepForestGreen,
          ),
        ),
        const SizedBox(height: 6),

        // 3. AUTHOR ATTRIBUTION
        Text.rich(
          TextSpan(
            text: 'by ',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: DSColors.textMuted,
            ),
            children: [
              TextSpan(
                text: widget.book.author,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: DSColors.deepForestGreen,
                ),
              ),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),

        // 4. RATINGS, VERIFIED BADGE & WISHLIST (Responsive Wrap)
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (widget.book.rating > 0) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (idx) {
                      return Icon(
                        idx < widget.book.rating.floor()
                            ? Icons.star_rounded
                            : (idx < widget.book.rating ? Icons.star_half_rounded : Icons.star_outline_rounded),
                        color: const Color(0xFFF59E0B),
                        size: 16,
                      );
                    }),
                  ),
                  Text(
                    widget.book.rating.toStringAsFixed(1),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: DSColors.charcoal,
                    ),
                  ),
                  Text(
                    widget.book.totalReviews > 0 ? '(${widget.book.totalReviews} reviews)' : '(1 review)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: DSColors.textMuted,
                    ),
                  ),
                ] else ...[
                  const Icon(Icons.star_outline_rounded, color: Color(0xFFA0AEC0), size: 16),
                  Text(
                    'Unrated',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DSColors.textMuted),
                  ),
                  Text(
                    '(No reviews yet)',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA0AEC0)),
                  ),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: DSColors.warmIvory,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.book.conditionVerification.isNotEmpty
                        ? widget.book.conditionVerification.toUpperCase()
                        : 'INSPECTED',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() => _isWishlisted = !_isWishlisted);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isWishlisted ? 'Added to Wishlist ♡' : 'Removed from Wishlist'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _isWishlisted ? const Color(0xFFFEF2F2) : DSColors.paperWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isWishlisted ? const Color(0xFFFECACA) : DSColors.softBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isWishlisted ? Icons.favorite : Icons.favorite_border,
                        size: 14,
                        color: _isWishlisted ? const Color(0xFFDC2626) : DSColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isWishlisted ? 'Wishlisted' : 'Add to Wishlist',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _isWishlisted ? const Color(0xFFDC2626) : DSColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 5. METADATA SPECIFICATIONS CARD
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: DSColors.paperWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DSColors.softBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildMetaItem(
                  icon: Icons.qr_code_2_rounded,
                  label: 'ISBN',
                  value: widget.book.isbn.isNotEmpty ? widget.book.isbn : 'Not listed',
                ),
              ),
              Container(width: 1, height: 32, color: DSColors.softBorder),
              Expanded(
                child: _buildMetaItem(
                  icon: Icons.business_outlined,
                  label: 'Publisher',
                  value: widget.book.publisher.isNotEmpty ? widget.book.publisher : 'Not specified',
                ),
              ),
              Container(width: 1, height: 32, color: DSColors.softBorder),
              Expanded(
                child: _buildMetaItem(
                  icon: Icons.translate_rounded,
                  label: 'Language',
                  value: widget.book.language.isNotEmpty ? widget.book.language : 'English',
                ),
              ),
              Container(width: 1, height: 32, color: DSColors.softBorder),
              Expanded(
                child: _buildMetaItem(
                  icon: Icons.menu_book_outlined,
                  label: 'Length',
                  value: pagesStr,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 6. DEDICATED PROVIDER / SELLER CARD
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DSColors.softBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: DSColors.deepForestGreen.withValues(alpha: 0.1),
                child: Text(
                  (widget.book.providerName ?? 'P').substring(0, 1).toUpperCase(),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: DSColors.deepForestGreen,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.book.providerName ?? 'Community Provider',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: DSColors.charcoal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.book.providerVerified) ...[
                          const SizedBox(width: 4),
                          const Tooltip(
                            message: 'Verified Marketplace Provider',
                            child: Icon(Icons.verified, size: 15, color: Color(0xFF2563EB)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.book.providerCampus != null && widget.book.providerCampus!.isNotEmpty
                          ? '📍 ${widget.book.providerCampus}'
                          : '📍 Campus location not specified',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: DSColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DSColors.paperWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: DSColors.softBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.book.providerRating != null
                          ? '★ ${widget.book.providerRating!.toStringAsFixed(1)}'
                          : 'New Seller',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: widget.book.providerRating != null
                            ? const Color(0xFFB45309)
                            : const Color(0xFF475569),
                      ),
                    ),
                    Text(
                      'Provider Rating',
                      style: GoogleFonts.inter(fontSize: 9.5, color: DSColors.textLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // 7. ABOUT THIS BOOK DESCRIPTION
        Text(
          'About this book',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: DSColors.deepForestGreen,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.book.description.isNotEmpty
              ? widget.book.description
              : 'No detailed description provided by the seller for this listing.',
          maxLines: _isDescriptionExpanded ? 100 : 3,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: DSColors.textMuted,
            height: 1.6,
          ),
        ),
        if (widget.book.description.length > 120)
          InkWell(
            onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isDescriptionExpanded ? 'Show less' : 'Show more',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: DSColors.deepForestGreen,
                    ),
                  ),
                  Icon(
                    _isDescriptionExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: DSColors.deepForestGreen,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMetaItem({required IconData icon, required String label, required String value}) {
    return Tooltip(
      message: '$label: $value',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: DSColors.deepForestGreen),
            const SizedBox(height: 5),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: DSColors.textLight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: DSColors.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
