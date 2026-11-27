import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../home/domain/entities/book.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import 'package:libri_flow/core/widgets/book_cover_image.dart';

class ProviderBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const ProviderBookCard({super.key, required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final currentPrice = book.price > 0 ? book.price.toStringAsFixed(0) : '350';
    final rentalPrice = book.canRent ? 'Rent Available' : null;

    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DSColors.softBorder.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Book Cover with shadow and fallback support
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: BookCoverImage(
              url: book.coverUrl,
              height: 180,
              width: 125,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            book.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: DSColors.textDark,
            ),
          ),
          if (book.author.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              book.author,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: DSColors.textLight,
              ),
            ),
          ],
          const SizedBox(height: 8),

          // Price row in ₹
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '₹$currentPrice',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: DSColors.primary,
                ),
              ),
              if (rentalPrice != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: DSColors.antiqueGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    rentalPrice,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8C6D1F),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: DSColors.primary,
                side: const BorderSide(color: DSColors.primary, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(
                'View Listing',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
