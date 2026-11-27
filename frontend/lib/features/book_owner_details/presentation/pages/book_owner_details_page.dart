import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../book_details/presentation/widgets/book_header.dart';
import '../../../book_details/presentation/widgets/hero_cover_image.dart';
import '../../../book_details/presentation/widgets/publication_details_card.dart';
import '../../../book_details/presentation/widgets/quote_card.dart';
import '../bloc/book_owner_details_bloc.dart';
import '../bloc/book_owner_details_state.dart';
import '../widgets/owner_bottom_action_bar.dart';
import '../widgets/owner_status_indicator.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import 'package:libri_flow/core/design_system/tokens/ds_radius.dart';

class BookOwnerDetailsPage extends StatelessWidget {
  const BookOwnerDetailsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.background,
      appBar: AppBar(
        title: const Text('Book Owner Details', style: TextStyle(color: DSColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: DSColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DSColors.textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: BlocBuilder<BookOwnerDetailsBloc, BookOwnerDetailsState>(
            builder: (context, state) {
        if (state is BookOwnerDetailsInitial ||
            state is BookOwnerDetailsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is BookOwnerDetailsError) {
          return Center(child: Text(state.message));
        }
        if (state is BookOwnerDetailsLoaded) {
          final details = state.listingDetails;
          final book = details.book;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: HeroCoverImage(imageUrl: book.coverUrl)),
                const SizedBox(height: 32),
                BookHeader(
                  title: book.title,
                  author: book.author,
                  isStaffPick: book.isStaffPick,
                  onReportIssue: () => context.push('/report-issue'),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: book.categories
                      .map(
                        (cat) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: DSColors.surface,
                            borderRadius: BorderRadius.circular(DSRadius.pill),
                          ),
                          child: Text(
                            cat.toUpperCase(),
                            style: const TextStyle(
                              color: DSColors.textDark,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 32),
                Text(
                  'SUMMARY',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    color: DSColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(height: 1, color: DSColors.borderLight),
                const SizedBox(height: 8),
                Text(
                  book.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: DSColors.textLight,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 600;
                    if (isSmallScreen) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PublicationDetailsCard(
                            title: 'Publication Details',
                            items: [
                              DetailItem('Edition', book.edition ?? 'N/A'),
                              DetailItem('Year', '2023'),
                              DetailItem('Page Count', book.pages ?? 'N/A'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          PublicationDetailsCard(
                            title: 'Publisher',
                            icon: Icons.history_edu,
                            items: [DetailItem('', book.publisher)],
                          ),
                          const SizedBox(height: 8),
                          PublicationDetailsCard(
                            title: 'Language',
                            icon: Icons.translate,
                            items: [DetailItem('', book.language)],
                          ),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: PublicationDetailsCard(
                            title: 'Publication Details',
                            items: [
                              DetailItem('Edition', book.edition ?? 'N/A'),
                              DetailItem('Year', '2023'),
                              DetailItem('Page Count', book.pages ?? 'N/A'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              PublicationDetailsCard(
                                title: 'Publisher',
                                icon: Icons.history_edu,
                                items: [
                                  DetailItem('Publisher', book.publisher),
                                ],
                              ),
                              const SizedBox(height: 16),
                              PublicationDetailsCard(
                                title: 'Language',
                                icon: Icons.translate,
                                items: [DetailItem('Language', book.language)],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (book.quote != null) ...[
                  const SizedBox(height: 32),
                  QuoteCard(
                    quote: book.quote!,
                    author: book.quoteAuthor ?? 'Unknown',
                  ),
                ],
                const SizedBox(height: 32),
                if (details.isVerified && details.isActive)
                  const OwnerStatusIndicator(),
                const SizedBox(height: 32),
                OwnerBottomActionBar(
                  onEdit: () => context.push('/sell'),
                  onMore: () => context.push('/provider-portfolio'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
