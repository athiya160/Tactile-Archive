import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import 'package:libri_flow/features/home/domain/entities/book.dart';
import 'package:libri_flow/core/widgets/book_cover_image.dart';

class HomeBestSellers extends StatelessWidget {
  final List<Book> books;

  const HomeBestSellers({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return const SizedBox.shrink();

    // Use up to 3 books for best sellers
    final bestSellers = books.take(3).toList();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.md,
        vertical: DSSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Best Sellers',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: DSColors.textDark,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/browse'),
                child: const Text(
                  'View all',
                  style: TextStyle(color: DSColors.textLight, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.md),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bestSellers.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 32, color: Color(0xFFEEEEEE)),
            itemBuilder: (context, index) {
              final book = bestSellers[index];
              return _buildBestSellerItem(context, book, index + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBestSellerItem(BuildContext context, Book book, int rank) {
    return GestureDetector(
      onTap: () => context.push('/book/${book.id}', extra: book),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Rank
          SizedBox(
            width: 24,
            child: Text(
              rank.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: DSColors.textLight,
              ),
            ),
          ),

          // Book Cover
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 50,
              height: 75,
              child: BookCoverImage(url: book.coverUrl),
            ),
          ),
          const SizedBox(width: DSSpacing.md),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: DSColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  book.author,
                  style: const TextStyle(
                    fontSize: 12,
                    color: DSColors.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      book.price > 0 ? (book.price < 50 ? '₹${(book.price * 83).toInt()}' : '₹${book.price.toInt()}') : 'Free',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: DSColors.textDark,
                      ),
                    ),
                    const SizedBox(width: DSSpacing.sm),
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      book.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        color: DSColors.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bookmark Icon
          IconButton(
            onPressed: () => context.push('/book/${book.id}', extra: book),
            icon: const Icon(Icons.bookmark_border, color: DSColors.textLight),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
