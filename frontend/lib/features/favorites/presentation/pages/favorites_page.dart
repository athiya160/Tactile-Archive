import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/auth_guard.dart';
import '../bloc/favorites_bloc.dart';
import '../bloc/favorites_event.dart';
import '../bloc/favorites_state.dart';
import '../widgets/book_list_card.dart';
import '../widgets/quote_section.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import 'package:libri_flow/core/widgets/tactile_footer.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    // Check auth when this tab is opened
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuth());
  }

  Future<void> _checkAuth() async {
    if (!ApiService.isLoggedIn) {
      await requireAuth(
        context,
        reason:
            'Sign in to save and view your favourite books across all your devices.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Guest/unauthenticated view
    if (!ApiService.isLoggedIn) {
      return _GuestFavouritesPrompt();
    }

    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            context.read<FavoritesBloc>().add(FavoritesStarted());
          },
          color: DSColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                Padding(
                  padding: const EdgeInsets.only(
                    top: 96,
                    left: DSSpacing.lg,
                    right: DSSpacing.lg,
                    bottom: 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A sanctuary for the volumes that spoke to your soul. Review, organize, or revisit your favorite literary journeys.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: DSColors.textLight,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                // Favorites List
                if (state is FavoritesLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator(color: DSColors.primary)),
                  )
                else if (state is FavoritesError)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text(state.message)),
                  )
                else if (state is FavoritesLoaded)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DSSpacing.lg),
                    child: state.favorites.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'Your shelf is empty. Discover new favorites in the catalog.',
                              ),
                            ),
                          )
                        : Column(
                            children: state.favorites.map((book) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: DSSpacing.md,
                                ),
                                child: BookListCard(
                                  book: book,
                                  onRemove: () {
                                    context.read<FavoritesBloc>().add(
                                      FavoritesRemovePressed(book.id),
                                    );
                                  },
                                  onTap: () => context.push('/book/${book.id}'),
                                ),
                              );
                            }).toList(),
                          ),
                  ),

                // Quote Section
                if (state is FavoritesLoaded && state.favorites.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: DSSpacing.lg,
                      vertical: 40,
                    ),
                    child: QuoteSection(
                      quote:
                          'A library is not a luxury but one of the necessities of life.',
                      author: 'Henry Ward Beecher',
                    ),
                  ),

                const SizedBox(height: 80),
                const TactileFooter(),
              ],
            ),
          ),
        );
      },
    );
  }
}
// ── Guest prompt when not logged in ─────────────────────────────────────────

class _GuestFavouritesPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: DSColors.primary.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                color: DSColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Favourites Await',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: DSColors.deepForestGreen,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Sign in to save books you love and access them anywhere, anytime.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: DSColors.textLight,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.push('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DSColors.primary,
                  foregroundColor: DSColors.textInverse,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DSRadius.xl),
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push('/register'),
              child: const Text(
                'Create Account',
                style: TextStyle(
                  color: DSColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
