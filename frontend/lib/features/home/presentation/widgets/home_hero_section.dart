import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';

/// Editorial Luxury Hero Section for The Tactile Archive
/// Provides:
/// - Prominent book search bar on both mobile & desktop
/// - Playfair Display headline & Inter subtext
/// - Quick discovery category pills
/// - Curated action buttons (Explore, Lend/Sell, Archive AI)
/// - Responsive scaling with zero layout overflow
class HomeHeroSection extends StatefulWidget {
  final VoidCallback onExplorePressed;
  final VoidCallback onSellPressed;

  const HomeHeroSection({
    super.key,
    required this.onExplorePressed,
    required this.onSellPressed,
  });

  @override
  State<HomeHeroSection> createState() => _HomeHeroSectionState();
}

class _HomeHeroSectionState extends State<HomeHeroSection> {
  final TextEditingController _heroSearchController = TextEditingController();

  static const _quickTags = [
    'Academic Textbooks',
    'Curated Fiction',
    'Computer Science',
    'Classics',
    'Free Swaps',
  ];

  @override
  void dispose() {
    _heroSearchController.dispose();
    super.dispose();
  }

  void _submitSearch(String query) {
    final q = query.trim();
    if (q.isNotEmpty) {
      context.go('/browse?search=${Uri.encodeComponent(q)}');
    } else {
      widget.onExplorePressed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width <= 768;
    final isTablet = screenSize.width > 768 && screenSize.width <= 1024;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A2F), // Editorial Forest Green
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A2F),
            Color(0xFF162E25),
            Color(0xFF12241D),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : (isTablet ? 32 : 48),
              vertical: isMobile ? 20 : 48,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. EDITORIAL EYEBROW BADGE
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 14,
                    vertical: isMobile ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: DSColors.antiqueGold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: DSColors.antiqueGold.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('✨', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 6),
                        Text(
                          'ONE WORLD • THREE WAYS TO READ',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 9.5 : 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: DSColors.antiqueGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),

                // 2. PLAYFAIR DISPLAY HEADLINE
                Text(
                  'Discover, Borrow & Share\nBooks Around You',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: isMobile ? 22 : (isTablet ? 36 : 46),
                    height: 1.2,
                    color: DSColors.paperWhite,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: isMobile ? 10 : 14),

                  // 3. EDITORIAL SUBTITLE
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Text(
                      'An intelligent book ecosystem connecting students, readers, and providers. Circulate textbooks, build your living bookshelf, and discover peer reading exchanges.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 14 : 16,
                        color: Colors.white.withValues(alpha: 0.92),
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 4. PROMINENT SEARCH BAR (Mobile & Desktop)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 660),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: DSColors.paperWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: DSColors.softBorder, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const FaIcon(
                            FontAwesomeIcons.magnifyingGlass,
                            size: 16,
                            color: DSColors.mutedTerracotta,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _heroSearchController,
                              onSubmitted: _submitSearch,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: DSColors.charcoal,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: isMobile
                                    ? 'Search title, author, ISBN...'
                                    : 'Search by title, author, syllabus, or ISBN...',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: DSColors.textMuted,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _submitSearch(_heroSearchController.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DSColors.deepForestGreen,
                              foregroundColor: DSColors.paperWhite,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 16 : 22,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Search',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 5. QUICK DISCOVERY TAGS
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: _quickTags.map((tag) {
                      return InkWell(
                        onTap: () {
                          if (tag == 'Free Swaps') {
                            context.go('/browse?filter=free');
                          } else {
                            context.go('/browse?category=${Uri.encodeComponent(tag)}');
                          }
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 26),

                  // 6. STREAMLINED ACTION BUTTONS
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      // Explore Books
                      ElevatedButton.icon(
                        onPressed: widget.onExplorePressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DSColors.antiqueGold,
                          foregroundColor: DSColors.charcoal,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 22,
                            vertical: isMobile ? 10 : 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 1,
                        ),
                        icon: const FaIcon(FontAwesomeIcons.compass, size: 13),
                        label: Text(
                          'Explore Catalog',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.5),
                        ),
                      ),

                      // Lend or Sell
                      OutlinedButton.icon(
                        onPressed: widget.onSellPressed,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 1.2),
                          backgroundColor: Colors.white.withValues(alpha: 0.10),
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 22,
                            vertical: isMobile ? 10 : 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const FaIcon(FontAwesomeIcons.bookOpen, size: 13),
                        label: Text(
                          'Lend / Sell Books',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12.5),
                        ),
                      ),

                      // Ask Archive AI
                      ElevatedButton.icon(
                        onPressed: () => context.push('/archive-ai'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DSColors.paperWhite,
                          foregroundColor: DSColors.deepForestGreen,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 22,
                            vertical: isMobile ? 10 : 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 1,
                        ),
                        icon: const Text('✨', style: TextStyle(fontSize: 12)),
                        label: Text(
                          'Ask Archive AI',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }
}
