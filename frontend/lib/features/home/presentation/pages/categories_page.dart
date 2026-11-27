import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/widgets/ivory_scaffold.dart';
import '../../../../core/design_system/tokens/ds_colors.dart';
import '../../../../core/widgets/tactile_footer.dart';
import 'package:libri_flow/core/design_system/tokens/ds_radius.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  static const List<Map<String, dynamic>> curatedCategories = [
    {
      'title': 'Fiction',
      'count': '1,240+ Books',
      'icon': FontAwesomeIcons.bookOpen,
      'color': DSColors.deepForestGreen,
      'bgColor': Color(0xFFE8F5E9),
      'subcategories': ['Literary Fiction', 'Sci-Fi', 'Fantasy', 'Classics', 'Historical'],
    },
    {
      'title': 'Academic & Textbooks',
      'count': '890+ Books',
      'icon': FontAwesomeIcons.graduationCap,
      'color': Color(0xFF2E7D32),
      'bgColor': Color(0xFFE0F2F1),
      'subcategories': ['Computer Science', 'Mathematics', 'Engineering', 'Medical', 'Economics'],
    },
    {
      'title': 'Tech & Programming',
      'count': '620+ Books',
      'icon': FontAwesomeIcons.laptopCode,
      'color': Color(0xFF1E40AF),
      'bgColor': Color(0xFFEFF6FF),
      'subcategories': ['System Design', 'AI & Machine Learning', 'Cloud Native', 'Web Dev', 'Algorithms'],
    },
    {
      'title': 'Business & Finance',
      'count': '540+ Books',
      'icon': FontAwesomeIcons.chartLine,
      'color': Color(0xFFB45309),
      'bgColor': Color(0xFFFEF3C7),
      'subcategories': ['Startups & VC', 'Investing', 'Leadership', 'Marketing', 'Economics'],
    },
    {
      'title': 'Self Development',
      'count': '710+ Books',
      'icon': FontAwesomeIcons.brain,
      'color': Color(0xFFC85A32),
      'bgColor': Color(0xFFFBEBE6),
      'subcategories': ['Habits', 'Productivity', 'Mindfulness', 'Psychology', 'Communication'],
    },
    {
      'title': 'Romance & Drama',
      'count': '430+ Books',
      'icon': FontAwesomeIcons.heart,
      'color': Color(0xFFBE185D),
      'bgColor': Color(0xFFFCE7F3),
      'subcategories': ['Contemporary', 'Historical Romance', 'Rom-Com', 'Fantasy Romance'],
    },
    {
      'title': 'Mystery & Thriller',
      'count': '580+ Books',
      'icon': FontAwesomeIcons.mask,
      'color': Color(0xFF4338CA),
      'bgColor': Color(0xFFEEF2FF),
      'subcategories': ['Crime & Detective', 'Psychological', 'Legal Thriller', 'Suspense', 'Espionage'],
    },
    {
      'title': 'Science & Nature',
      'count': '390+ Books',
      'icon': FontAwesomeIcons.atom,
      'color': Color(0xFF047857),
      'bgColor': Color(0xFFECFDF5),
      'subcategories': ['Physics & Cosmos', 'Biology', 'Climate & Ecology', 'Neuroscience', 'Evolution'],
    },
    {
      'title': 'History & Biography',
      'count': '460+ Books',
      'icon': FontAwesomeIcons.landmark,
      'color': Color(0xFF7C2D12),
      'bgColor': Color(0xFFFEF2F2),
      'subcategories': ['World History', 'Memoirs', 'Ancient Civilizations', 'Military', 'Biographies'],
    },
    {
      'title': 'Poetry & Arts',
      'count': '280+ Books',
      'icon': FontAwesomeIcons.featherPointed,
      'color': Color(0xFF6B21A8),
      'bgColor': Color(0xFFFAF5FF),
      'subcategories': ['Classical Poetry', 'Contemporary', 'Plays & Theater', 'Art & Design'],
    },
    {
      'title': 'Children & Young Adult',
      'count': '520+ Books',
      'icon': FontAwesomeIcons.shapes,
      'color': Color(0xFFD97706),
      'bgColor': Color(0xFFFFFBEB),
      'subcategories': ['YA Fantasy', 'Middle Grade', 'Picture Books', 'Graphic Novels', 'Comics'],
    },
    {
      'title': 'Rare Finds & Collectibles',
      'count': '150+ Books',
      'icon': FontAwesomeIcons.gem,
      'color': Color(0xFFD69E2E),
      'bgColor': Color(0xFFFFF9E6),
      'subcategories': ['First Editions', 'Signed Copies', 'Vintage Editions', 'Folio Society', 'Antiquarian'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return IvoryScaffold(
      showAppBar: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1000;

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16.0 : (isTablet ? 28.0 : 48.0),
                vertical: isMobile ? 24.0 : 40.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Explore by Category',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: isMobile ? 28 : 38,
                                fontWeight: FontWeight.bold,
                                color: DSColors.forestGreen,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Discover 12 curated genres with community hubs, direct rentals, and exchanges.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: DSColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isMobile)
                        ElevatedButton.icon(
                          onPressed: () => context.push('/ai-concierge'),
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('AI Concierge Match'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DSColors.forestGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 12 CATEGORIES GRID
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: curatedCategories.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 18,
                      mainAxisExtent: 220,
                    ),
                    itemBuilder: (context, index) {
                      final item = curatedCategories[index];
                      final color = item['color'] as Color;
                      final bgColor = item['bgColor'] as Color;
                      final title = item['title'] as String;
                      final count = item['count'] as String;
                      final subcategories = item['subcategories'] as List<String>;

                      return InkWell(
                        onTap: () => context.go('/browse?category=${Uri.encodeComponent(title)}'),
                        borderRadius: BorderRadius.circular(DSRadius.card),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(DSRadius.card),
                            border: Border.all(color: DSColors.borderLight),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: FaIcon(item['icon'] as dynamic, size: 20, color: color),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: GoogleFonts.playfairDisplay(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: DSColors.forestGreen,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          count,
                                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: DSColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios, size: 12, color: DSColors.textMuted.withValues(alpha: 0.5)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: subcategories.take(4).map((sub) {
                                  return InkWell(
                                    onTap: () => context.go('/browse?category=${Uri.encodeComponent(sub)}'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: DSColors.background,
                                        borderRadius: BorderRadius.circular(DSRadius.sm),
                                        border: Border.all(color: DSColors.border),
                                      ),
                                      child: Text(
                                        sub,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: DSColors.textDark,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 48),

                  // BOTTOM CALLOUT
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 24.0 : 36.0),
                    decoration: BoxDecoration(
                      color: DSColors.warmIvory,
                      borderRadius: BorderRadius.circular(DSRadius.card),
                      border: Border.all(color: DSColors.softBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Need a specific textbook or rare print?',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: DSColors.forestGreen,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Use AI reading concierge or explore community listings across 5,000+ local members.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: DSColors.deepForestGreen,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Wrap(
                                spacing: 12,
                                runSpacing: 10,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => context.go('/browse'),
                                    icon: const Icon(Icons.search, size: 16),
                                    label: const Text('Browse All Titles'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: DSColors.forestGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => context.push('/ai-shelf-scanner'),
                                    icon: const Icon(Icons.camera_alt, size: 16),
                                    label: const Text('Scan Your Shelf'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: DSColors.forestGreen,
                                      side: const BorderSide(color: DSColors.forestGreen),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
            const TactileFooter(),
          ],
        ),
      );
        },
      ),
    );
  }
}
