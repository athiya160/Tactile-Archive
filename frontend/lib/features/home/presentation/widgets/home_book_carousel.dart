import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/book.dart';
import '../bloc/home_bloc.dart';

/// Editorial Book Carousel for The Tactile Archive
/// Showcases books using the luxury EditorialBookCard with 3D tactile depth,
/// spine lighting, and interactive controls.
class HomeBookCarousel extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<Book> books;

  const HomeBookCarousel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.books,
  });

  @override
  State<HomeBookCarousel> createState() => _HomeBookCarouselState();
}

class _HomeBookCarouselState extends State<HomeBookCarousel> {
  final ScrollController _scrollController = ScrollController();

  void _scroll(int direction) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final double amount = position.viewportDimension * 0.75;
    final target = position.pixels + (direction * amount);

    _scrollController.animateTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.books.isEmpty) return const SizedBox.shrink();

    final isNarrow = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.symmetric(vertical: isNarrow ? 20 : 36),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              SizedBox(
                height: isNarrow ? 360 : 400,
                child: ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.books.length,
                  separatorBuilder: (context, index) => SizedBox(width: isNarrow ? 12 : 16),
                  itemBuilder: (context, index) {
                    final book = widget.books[index];
                    final availability = book.listingType == ListingType.forRent
                        ? 'Rent'
                        : (book.price == 0 ? 'Borrow' : 'Buy');

                    return EditorialBookCard(
                      title: book.title,
                      author: book.author,
                      price: book.price,
                      imageUrl: book.coverUrl,
                      condition: book.conditionVerification,
                      availability: availability,
                      providerName: book.publisher.isNotEmpty ? book.publisher : 'The Tactile Archive',
                      rating: book.rating,
                      reviewCount: book.totalReviews,
                      isFavorite: book.isFavorite,
                      width: isNarrow ? 175 : 195,
                      imageHeight: isNarrow ? 155 : 175,
                      onTap: () => context.go('/book/${book.id}'),
                      onFavoriteToggle: () {
                        context.read<HomeBloc>().add(HomeFavoriteToggled(book.id));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 2,
                    color: DSColors.mutedTerracotta,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'CURATED SELECTION',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: DSColors.mutedTerracotta,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: DSColors.charcoal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: DSColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            _CarouselButton(
              icon: FontAwesomeIcons.chevronLeft,
              onTap: () => _scroll(-1),
            ),
            const SizedBox(width: 8),
            _CarouselButton(
              icon: FontAwesomeIcons.chevronRight,
              onTap: () => _scroll(1),
            ),
          ],
        ),
      ],
    );
  }
}

class _CarouselButton extends StatefulWidget {
  final dynamic icon;
  final VoidCallback onTap;

  const _CarouselButton({required this.icon, required this.onTap});

  @override
  State<_CarouselButton> createState() => _CarouselButtonState();
}

class _CarouselButtonState extends State<_CarouselButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isHovered ? DSColors.deepForestGreen : DSColors.paperWhite,
            border: Border.all(
              color: _isHovered ? DSColors.deepForestGreen : DSColors.softBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: FaIcon(
              widget.icon,
              size: 13,
              color: _isHovered ? Colors.white : DSColors.deepForestGreen,
            ),
          ),
        ),
      ),
    );
  }
}
