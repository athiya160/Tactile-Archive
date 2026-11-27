import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class HomeAnimatedCategorySection extends StatefulWidget {
  final Function(String) onCategorySelected;

  const HomeAnimatedCategorySection({
    super.key,
    required this.onCategorySelected,
  });

  @override
  State<HomeAnimatedCategorySection> createState() => _HomeAnimatedCategorySectionState();
}

class _HomeAnimatedCategorySectionState extends State<HomeAnimatedCategorySection> {
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Academic & Textbooks',
      'subtitle': 'Engineering, Medical & Degree',
      'icon': FontAwesomeIcons.graduationCap,
      'color': const Color(0xFFE8F5E9),
      'accent': const Color(0xFF2E7D32),
    },
    {
      'name': 'Fiction',
      'subtitle': 'Novels, Mystery & Sci-Fi',
      'icon': FontAwesomeIcons.bookOpen,
      'color': const Color(0xFFE0F2F1),
      'accent': const Color(0xFF00695C),
    },
    {
      'name': 'Non-Fiction',
      'subtitle': 'Self-Help, Biography & Mindset',
      'icon': FontAwesomeIcons.penNib,
      'color': const Color(0xFFFFF3E0),
      'accent': const Color(0xFFE65100),
    },
    {
      'name': 'Science & Tech',
      'subtitle': 'Coding, AI & Research',
      'icon': FontAwesomeIcons.laptopCode,
      'color': const Color(0xFFE8EAF6),
      'accent': const Color(0xFF283593),
    },
    {
      'name': 'Competitive Exams',
      'subtitle': 'GATE, UPSC, JEE & NEET',
      'icon': FontAwesomeIcons.award,
      'color': const Color(0xFFFCE4EC),
      'accent': const Color(0xFFC2185B),
    },
    {
      'name': 'Children & Comics',
      'subtitle': 'Graphic Novels & Storybooks',
      'icon': FontAwesomeIcons.masksTheater,
      'color': const Color(0xFFFFF8E1),
      'accent': const Color(0xFFF57F17),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFDFBF7),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECTION HEADER WITH SLIDE & FADE ANIMATION
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 650;
                  final titleCol = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EE),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'EXPLORE MARKETPLACE',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0D3B2E),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Browse by Category',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: isNarrow ? 22 : 32,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF252923),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Find textbooks, fiction, research volumes, and rare editions',
                        style: GoogleFonts.inter(
                          fontSize: isNarrow ? 12 : 14,
                          color: const Color(0xFF718096),
                        ),
                      ),
                    ],
                  );

                  final viewAllBtn = InkWell(
                    onTap: () => context.go('/browse'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View all categories',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0D3B2E),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF0D3B2E)),
                        ],
                      ),
                    ),
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleCol,
                        const SizedBox(height: 12),
                        viewAllBtn,
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: titleCol),
                      const SizedBox(width: 16),
                      viewAllBtn,
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // ANIMATED CATEGORY CARDS GRID
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 640;
                final crossCount = constraints.maxWidth >= 1024
                    ? 3
                    : (constraints.maxWidth >= 640 ? 2 : 2);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossCount,
                    childAspectRatio: constraints.maxWidth >= 1024 ? 2.4 : (isMobile ? 2.1 : 2.2),
                    crossAxisSpacing: isMobile ? 10 : 16,
                    mainAxisSpacing: isMobile ? 10 : 16,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];

                    // STAGGERED FADE & SLIDE ANIMATION PER CARD
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 500 + (index * 100)),
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: _CategoryAnimatedCard(
                        category: cat,
                        onTap: () => widget.onCategorySelected(cat['name'] as String),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryAnimatedCard extends StatefulWidget {
  final Map<String, dynamic> category;
  final VoidCallback onTap;

  const _CategoryAnimatedCard({
    required this.category,
    required this.onTap,
  });

  @override
  State<_CategoryAnimatedCard> createState() => _CategoryAnimatedCardState();
}

class _CategoryAnimatedCardState extends State<_CategoryAnimatedCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 640;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : 18,
              vertical: isMobile ? 10 : 16,
            ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? (widget.category['accent'] as Color).withValues(alpha: 0.5)
                  : const Color(0xFFEDF2F7),
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? (widget.category['accent'] as Color).withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: _isHovered ? 16 : 8,
                offset: Offset(0, _isHovered ? 8 : 2),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isMobile ? 36 : 48,
                height: isMobile ? 36 : 48,
                decoration: BoxDecoration(
                  color: widget.category['color'] as Color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: FaIcon(
                    widget.category['icon'] as dynamic,
                    size: isMobile ? 15 : 20,
                    color: widget.category['accent'] as Color,
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 8 : 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.category['name'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 12.5 : 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF252923),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.category['subtitle'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 10 : 12,
                        color: const Color(0xFF77786F),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isHovered ? 1.0 : 0.4,
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: widget.category['accent'] as Color,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
