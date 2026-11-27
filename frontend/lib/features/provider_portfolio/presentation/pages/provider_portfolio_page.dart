import 'package:libri_flow/core/widgets/ivory_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/provider_portfolio_bloc.dart';
import '../bloc/provider_portfolio_state.dart';
import '../widgets/provider_hero_section.dart';
import '../widgets/provider_book_card.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class ProviderPortfolioPage extends StatelessWidget {
  const ProviderPortfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProviderPortfolioBloc, ProviderPortfolioState>(
      builder: (context, state) {
        return IvoryScaffold(
          title: state is ProviderPortfolioLoaded
              ? '${state.providerName}\'s Archive'
              : 'Provider Catalog',
          showAppBar: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: DSColors.primary),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/provider');
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_box_outlined, color: DSColors.primary),
              tooltip: 'Add Book Listing',
              onPressed: () => context.push('/add-book'),
            ),
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, color: DSColors.primary),
              tooltip: 'Cart',
              onPressed: () => context.go('/cart'),
            ),
          ],
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ProviderPortfolioState state) {
    if (state is ProviderPortfolioLoading ||
        state is ProviderPortfolioInitial) {
      return const Center(child: CircularProgressIndicator(color: DSColors.primary));
    }
    if (state is ProviderPortfolioError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: DSColors.error),
              const SizedBox(height: 16),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: DSColors.textDark),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/provider'),
                style: ElevatedButton.styleFrom(backgroundColor: DSColors.primary),
                child: const Text('Back to Dashboard', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }
    if (state is ProviderPortfolioLoaded) {
      return SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            ProviderHeroSection(
              featuredBook: state.featuredBook,
              onViewMore: () => context.push('/book/${state.featuredBook.id}'),
            ),
            Container(
              width: double.infinity,
              color: DSColors.warmIvory,
              padding: const EdgeInsets.symmetric(
                vertical: 48.0,
                horizontal: 24.0,
              ),
              child: Column(
                children: [
                  Text(
                    'ARCHIVAL COLLECTION',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: DSColors.antiqueGold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Listed Volumes',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: DSColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${state.books.length} curated volumes available for rental and sale',
                    style: GoogleFonts.inter(fontSize: 13, color: DSColors.textLight),
                  ),
                  const SizedBox(height: 36),
                  if (state.books.isEmpty)
                    _buildEmptyInventoryState(context)
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 1100
                            ? 4
                            : (constraints.maxWidth > 800
                                ? 3
                                : (constraints.maxWidth > 520 ? 2 : 1));
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: 0.58,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 24,
                          ),
                          itemCount: state.books.length,
                          itemBuilder: (context, index) {
                            return Center(
                              child: ProviderBookCard(
                                book: state.books[index],
                                onTap: () => context.push(
                                  '/book/${state.books[index].id}',
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmptyInventoryState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DSColors.softBorder.withValues(alpha: 0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DSColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_stories_outlined,
              size: 40,
              color: DSColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your Inventory is Currently Empty',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: DSColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'List textbooks, rare editions, or study materials to make them available for students and readers across campus hubs.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: DSColors.textLight,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/add-book'),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              'Add First Book Listing',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: DSColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
