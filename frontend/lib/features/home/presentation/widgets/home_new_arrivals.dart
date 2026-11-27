import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import 'package:libri_flow/features/home/domain/entities/book.dart';
import 'package:libri_flow/core/widgets/book_cover_image.dart';

class HomeNewArrivals extends StatelessWidget {
  final List<Book> books;

  const HomeNewArrivals({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return const SizedBox.shrink();

    // Use a subset of books for new arrivals
    final newArrivals = books.length > 3 ? books.sublist(3) : books;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: DSSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DSSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'New Arrivals',
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
          ),
          const SizedBox(height: DSSpacing.md),
          SizedBox(
            height: 220,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: DSSpacing.md),
              scrollDirection: Axis.horizontal,
              itemCount: newArrivals.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: DSSpacing.md),
              itemBuilder: (context, index) {
                final book = newArrivals[index];
                return _buildNewArrivalCard(context, book);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewArrivalCard(BuildContext context, Book book) {
    return GestureDetector(
      onTap: () => context.push('/book/${book.id}', extra: book),
      child: SizedBox(
        width: 100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 100,
                height: 150,
                child: BookCoverImage(url: book.coverUrl),
              ),
            ),
            const SizedBox(height: DSSpacing.sm),

            // Details
            Text(
              book.title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: DSColors.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              book.author,
              style: const TextStyle(fontSize: 10, color: DSColors.textLight),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              book.price > 0 ? (book.price < 50 ? '₹${(book.price * 83).toInt()}' : '₹${book.price.toInt()}') : 'Free',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: DSColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
