import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/design_system.dart';
import 'package:flutter/material.dart';
import '../../../home/domain/entities/book.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BookReviewsSection extends StatelessWidget {
  final Book book;

  const BookReviewsSection({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    // For now, we simulate reviews. If there are no reviews, we show a "No reviews yet" message.
    final bool hasReviews = book.totalReviews > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Reviews',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: DSColors.deepForestGreen,
          ),
        ),
        const SizedBox(height: 24),
        if (!hasReviews)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(
                  FontAwesomeIcons.commentSlash,
                  size: 48,
                  color: Color(0xFFCCCCCC),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No reviews yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF555555),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Be the first to share your thoughts on this book!',
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () {
                    // Implement Write Review logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Review functionality coming soon!')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0B3D2E),
                    side: const BorderSide(color: Color(0xFF0B3D2E)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Write a Review'),
                ),
              ],
            ),
          )
        else
          // Placeholder for when we have actual reviews
          const SizedBox(),
      ],
    );
  }
}
