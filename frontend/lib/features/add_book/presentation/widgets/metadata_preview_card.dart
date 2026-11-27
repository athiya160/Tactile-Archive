import 'package:flutter/material.dart';
import '../../../home/domain/entities/book.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class MetadataPreviewCard extends StatelessWidget {
  final Book book;

  const MetadataPreviewCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DSColors.border,
        borderRadius: BorderRadius.circular(DSRadius.lg),
        boxShadow: DSShadows.md,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book Cover
          Container(
            width: 100,
            height: 140,
            decoration: BoxDecoration(color: DSColors.borderLight),
            child: Image.network(
              book.coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.book, color: DSColors.borderLight),
              ),
            ),
          ),
          // Book Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(DSSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: 'Noto Serif',
                      fontWeight: FontWeight.bold,
                      color: DSColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DSSpacing.xs),
                  Text(
                    'by ${book.author}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: DSColors.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: DSSpacing.sm),
                  if (book.description.isNotEmpty)
                    Text(
                      book.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DSColors.textLight.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
