import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../../core/widgets/badge_pill.dart';
import '../../domain/entities/book.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class FeaturedHero extends StatelessWidget {
  final Book book;

  const FeaturedHero({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/book/${book.id}'),
      child: Column(
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DSRadius.xl),
                  child: Image.network(
                    book.coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: DSColors.borderLight,
                      child: const Icon(Icons.book, size: 64),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DSRadius.xl),
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                ),
              ),
              Positioned(
                bottom: DSSpacing.lg,
                left: DSSpacing.lg,
                right: DSSpacing.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BadgePill(
                      label: 'Staff Pick',
                      backgroundColor: DSColors.secondary,
                      textColor: DSColors.textInverse,
                    ),
                    const SizedBox(height: DSSpacing.xs),
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      maxLines: 2,
                    ),
                    Text(
                      'By ${book.author}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.md),
          Container(
            padding: const EdgeInsets.all(DSSpacing.lg),
            decoration: BoxDecoration(
              color: DSColors.surface,
              borderRadius: BorderRadius.circular(DSRadius.xl),
              border: Border.all(color: DSColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why we love it',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DSSpacing.sm),
                Text(
                  book.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DSColors.textDark.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: DSSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (ApiService.isLoggedIn) {
                        context.push('/book/${book.id}');
                      } else {
                        final ok = await requireAuth(
                          context,
                          reason: 'Sign in to rent or borrow from the catalog.',
                        );
                        if (ok && context.mounted) {
                          context.push('/book/${book.id}');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DSColors.primary,
                      foregroundColor: DSColors.textInverse,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DSRadius.xl),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Rent for ₹${book.price.toStringAsFixed(0)} / week',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
