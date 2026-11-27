import 'package:flutter/material.dart';


import 'package:libri_flow/features/home/domain/entities/book.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'book_card.dart';

class HomeFeaturedCarousel extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<Book> books;
  const HomeFeaturedCarousel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.books,
  });

  @override
  State<HomeFeaturedCarousel> createState() => _HomeFeaturedCarouselState();
}

class _HomeFeaturedCarouselState extends State<HomeFeaturedCarousel> {
  final ScrollController _scrollController = ScrollController();
  void _scroll(int direction) {
    if (!_scrollController.hasClients) return;
    final amount = MediaQuery.sizeOf(context).width * 0.5;
    final target = _scrollController.offset + (direction * amount);
    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(color: const Color(0xFF0B3D2E)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xFF4A4A4A)),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _CarouselBtn(
                          icon: FontAwesomeIcons.chevronLeft,
                          onTap: () => _scroll(-1),
                        ),
                        const SizedBox(width: 8),
                        _CarouselBtn(
                          icon: FontAwesomeIcons.chevronRight,
                          onTap: () => _scroll(1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 400,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: (MediaQuery.sizeOf(context).width > 1200)
                    ? (MediaQuery.sizeOf(context).width - 1200) / 2 + 24
                    : 24,
              ),
              itemCount: widget.books.length,
              separatorBuilder: (context, index) => const SizedBox(width: 20),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 250,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0, top: 8),
                    child: BookCard(book: widget.books[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselBtn extends StatefulWidget {
  final dynamic icon;
  final VoidCallback onTap;
  const _CarouselBtn({required this.icon, required this.onTap});

  @override
  State<_CarouselBtn> createState() => _CarouselBtnState();
}

class _CarouselBtnState extends State<_CarouselBtn> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFF0B3D2E)
                : const Color(0xFFF0F0F0),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: FaIcon(
              widget.icon,
              size: 16,
              color: _isHovered ? Colors.white : const Color(0xFF0B3D2E),
            ),
          ),
        ),
      ),
    );
  }
}
