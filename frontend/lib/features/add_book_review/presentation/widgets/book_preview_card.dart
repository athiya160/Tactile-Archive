import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class BookPreviewCard extends StatelessWidget {
  final String title;
  final String author;
  final String isbn13;
  final String edition;
  final String? coverUrl;
  final String? localImagePath;

  const BookPreviewCard({
    super.key,
    required this.title,
    required this.author,
    required this.isbn13,
    required this.edition,
    this.coverUrl,
    this.localImagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DSSpacing.lg),
      decoration: BoxDecoration(
        color: DSColors.border,
        borderRadius: BorderRadius.circular(DSRadius.xl),
        boxShadow: DSShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Stack(
              children: [
                Container(
                  height: 240,
                  width: 160,
                  decoration: BoxDecoration(
                    color: DSColors.borderLight,
                    borderRadius: BorderRadius.circular(DSRadius.sm),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(DSRadius.sm),
                    child: coverUrl != null
                        ? Image.network(coverUrl!, fit: BoxFit.cover)
                        : const Icon(
                            Icons.book,
                            size: 64,
                            color: DSColors.border,
                          ),
                  ),
                ),
                Positioned(
                  bottom: -8,
                  right: -8,
                  child: GestureDetector(
                    onTap: () {
                      // Placeholder for edit cover
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: DSColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DSSpacing.xl),
          Text("PRIMARY IDENTIFICATION", style: IvoryTheme.smallCapsLabel),
          const SizedBox(height: DSSpacing.sm),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontFamily: 'Noto Serif',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DSSpacing.xs),
          Text(
            author,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: DSColors.textLight),
          ),
          const SizedBox(height: DSSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("ISBN-13", style: IvoryTheme.smallCapsLabel),
                    const SizedBox(height: DSSpacing.xs),
                    Text(
                      isbn13,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("EDITION", style: IvoryTheme.smallCapsLabel),
                    const SizedBox(height: DSSpacing.xs),
                    Text(
                      edition,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
