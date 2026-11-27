import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/tokens/app_tokens.dart';

class HomeCategoryShowcase extends StatelessWidget {
  final Function(String) onCategorySelected;
  final bool showTitleAndButton;
  final List<dynamic> categories;

  const HomeCategoryShowcase({
    super.key,
    required this.onCategorySelected,
    this.showTitleAndButton = true,
    required this.categories,
  });

  dynamic _getIconForCategory(String name) {
    switch (name.toLowerCase()) {
      case 'textbooks':
        return FontAwesomeIcons.graduationCap;
      case 'fiction':
        return FontAwesomeIcons.book;
      case 'non-fiction':
        return FontAwesomeIcons.penNib;
      case 'technology':
      case 'programming':
        return FontAwesomeIcons.laptopCode;
      case 'psychology':
        return FontAwesomeIcons.brain;
      case 'romance':
        return FontAwesomeIcons.heart;
      case 'science':
        return FontAwesomeIcons.flask;
      case 'business':
        return FontAwesomeIcons.briefcase;
      case 'history':
        return FontAwesomeIcons.landmark;
      case 'children':
        return FontAwesomeIcons.childReaching;
      case 'rare books':
        return FontAwesomeIcons.gem;
      default:
        return FontAwesomeIcons.layerGroup;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerLowest, // Premium clean background
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400),
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showTitleAndButton) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 24,
                              height: 2,
                              color: AppColors.tertiary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'GENRES',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: AppColors.tertiary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Explore Categories',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => onCategorySelected('all'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View All',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const FaIcon(FontAwesomeIcons.arrowRight, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
              ],
              _buildGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    // Premium specific categories matching the examples given
    final List<Map<String, dynamic>> displayData = categories.isEmpty
        ? [
            {'name': 'Fiction', 'count': '12,450'},
            {'name': 'Programming', 'count': '8,230'},
            {'name': 'Science', 'count': '6,300'},
            {'name': 'History', 'count': '4,100'},
            {'name': 'Business', 'count': '5,400'},
            {'name': 'Children', 'count': '3,800'},
            {'name': 'Romance', 'count': '9,800'},
            {'name': 'Rare Books', 'count': '850'},
          ]
        : categories.map((c) => {'name': c, 'count': '1,200'}).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 900) {
          crossAxisCount = 2;
        } else if (constraints.maxWidth < 1200) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.25, // Wider aspect ratio for premium look
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
          ),
          itemCount: displayData.length > 8 ? 8 : displayData.length,
          itemBuilder: (context, index) {
            final c = displayData[index];
            final name = c['name'] as String;
            final count = c['count'] as String;
            return _CategoryCard(
              title: name,
              icon: _getIconForCategory(name),
              description: '$count Books',
              onTap: () => onCategorySelected(name),
            );
          },
        );
      },
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String title;
  final dynamic icon;
  final String description;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.description,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? -8 : 0, 0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.primaryContainer : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered ? AppColors.tertiary.withOpacity(0.5) : AppColors.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _isHovered ? Colors.white : AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: AnimatedScale(
                    scale: _isHovered ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: FaIcon(
                      widget.icon,
                      color: _isHovered ? AppColors.tertiary : AppColors.primary,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _isHovered ? AppColors.onSurfaceVariant : AppColors.onSurfaceVariant.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
