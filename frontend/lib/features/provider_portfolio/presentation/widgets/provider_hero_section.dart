import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../home/domain/entities/book.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import 'package:libri_flow/core/widgets/book_cover_image.dart';

class ProviderHeroSection extends StatelessWidget {
  final Book featuredBook;
  final VoidCallback onViewMore;

  const ProviderHeroSection({
    super.key,
    required this.featuredBook,
    required this.onViewMore,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        if (isDesktop) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: DSColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DSColors.antiqueGold.withValues(alpha: 0.3), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 6, child: _buildTextContent(context)),
                const SizedBox(width: 32),
                Expanded(flex: 5, child: _buildImageContent()),
              ],
            ),
          );
        } else {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: DSColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DSColors.antiqueGold.withValues(alpha: 0.3), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildImageContent(),
                const SizedBox(height: 24),
                _buildTextContent(context),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildTextContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: DSColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: DSColors.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                'FEATURED CATALOG UPLOAD',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: DSColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (featuredBook.rating > 0)
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Color(0xFFD4AF37)),
                  const SizedBox(width: 4),
                  Text(
                    featuredBook.rating.toStringAsFixed(1),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: DSColors.textDark,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          featuredBook.title.isNotEmpty ? featuredBook.title : 'Best Selling Volume',
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: DSColors.primary,
          ),
        ),
        if (featuredBook.author.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'by ${featuredBook.author}',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: DSColors.textLight,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          featuredBook.description.isNotEmpty
              ? featuredBook.description
              : 'A distinguished archival piece curated for The Tactile Archive lending and collector marketplace.',
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: DSColors.textDark.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onViewMore,
          icon: const Icon(Icons.menu_book_rounded, size: 16),
          label: Text(
            'VIEW BOOK DETAILS',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.8,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: DSColors.primary,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: DSColors.primary.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(4, 8),
            ),
          ],
        ),
        child: BookCoverImage(
          url: featuredBook.coverUrl,
          height: 320,
          width: 220,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
