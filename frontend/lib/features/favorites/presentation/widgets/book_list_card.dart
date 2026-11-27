import 'package:flutter/material.dart';
import '../../../../core/widgets/rating_chip.dart';
import '../../../home/domain/entities/book.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class BookListCard extends StatelessWidget {
  final Book book;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const BookListCard({
    super.key,
    required this.book,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 144,
      margin: const EdgeInsets.only(bottom: DSSpacing.lg), // space-y-6
      decoration: BoxDecoration(
        color: DSColors.border,
        borderRadius: BorderRadius.circular(DSRadius.lg),
        border: Border.all(color: DSColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            // Cover Image with board cut effect
            Container(
              width: 112,
              height: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: DSColors.textDark.withValues(
                      alpha: 0.05,
                    ), // Digital board cut
                    width: 1,
                  ),
                ),
              ),
              child: Image.network(
                book.coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.book, size: 32)),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(DSSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (book.categories.isNotEmpty
                                        ? book.categories.first
                                        : 'UNCATEGORIZED')
                                    .toUpperCase(),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0, // tracking-wider
                                      color: DSColors.textLight,
                                      fontSize: 10,
                                    ),
                              ),
                              const SizedBox(height: DSSpacing.xs),
                              Text(
                                book.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontSize: 18, // text-lg
                                      color: DSColors.primary,
                                      height: 1.2,
                                    ),
                              ),
                              Text(
                                book.author,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: DSColors.textLight,
                                      fontSize: 14, // text-sm
                                    ),
                              ),
                            ],
                          ),
                        ),
                        RatingChip(
                          rating: book.rating,
                          color: DSColors.primary,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: onTap,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'READ NOW',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.0, // tracking-widest
                                  color: DSColors.primary,
                                  fontSize: 12, // text-xs
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: onRemove,
                          icon: const Icon(
                            Icons.heart_broken_outlined,
                            size: 18,
                          ),
                          color: DSColors.border,
                          tooltip: 'Remove from Favorites',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          style: IconButton.styleFrom(
                            foregroundColor: DSColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
