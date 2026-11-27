import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:libri_flow/features/home/presentation/bloc/home_bloc.dart';
import 'package:libri_flow/features/home/domain/entities/book.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import 'package:libri_flow/core/widgets/login_required_dialog.dart';

import 'package:libri_flow/features/home/presentation/widgets/home_hero_section.dart';
import 'package:libri_flow/features/home/presentation/widgets/home_benefits_bar.dart';
import 'package:libri_flow/features/home/presentation/widgets/home_feature_cards_row.dart';
import 'package:libri_flow/features/home/presentation/widgets/home_animated_category_section.dart';
import 'package:libri_flow/features/home/presentation/widgets/home_book_carousel.dart';
import 'package:libri_flow/features/home/presentation/widgets/home_exchange_hubs_preview.dart';
import 'package:libri_flow/features/home/presentation/widgets/home_steps_section.dart';
import 'package:libri_flow/features/home/presentation/widgets/home_why_choose_us_section.dart';
import 'package:libri_flow/features/home/presentation/widgets/home_sell_cta_section.dart';
import 'package:libri_flow/features/home/presentation/widgets/home_reader_passport_preview.dart';
import 'package:libri_flow/features/home/presentation/widgets/home_testimonials.dart';
import 'package:libri_flow/features/home/presentation/widgets/home_newsletter.dart';
import 'package:libri_flow/features/home/presentation/widgets/home_footer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(HomeStarted());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCategories() {
    context.go('/browse');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.warmIvory,
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return _buildBody(context, state);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    if (state is HomeInitial || (state is HomeLoading && state is! HomeLoaded)) {
      return const DSLoadingWidget();
    }

    if (state is HomeError) {
      return Center(
        child: Text(
          state.message,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: DSColors.error),
        ),
      );
    }

    if (state is HomeLoaded) {
      return RefreshIndicator(
        color: DSColors.primary,
        onRefresh: () async {
          context.read<HomeBloc>().add(HomeStarted());
        },
        child: _buildHomeContent(context, state),
      );
    }

    return const SizedBox.shrink();
  }

  // ==========================================
  // AUTHENTIC THE TACTILE ARCHIVE EXPERIENCE
  // ==========================================
  Widget _buildHomeContent(BuildContext context, HomeLoaded state) {
    final catalog = state.catalogBooks;
    final academicBooks = catalog
        .where((b) => b.categories.any((c) =>
            c.toLowerCase().contains('textbook') ||
            c.toLowerCase().contains('academic') ||
            c.toLowerCase().contains('tech') ||
            c.toLowerCase().contains('study')))
        .toList();
    final freeSwaps = catalog
        .where((b) => b.listingType == ListingType.forRent || b.price == 0)
        .toList();

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. LITERARY HERO SECTION
          HomeHeroSection(
            onExplorePressed: _scrollToCategories,
            onSellPressed: () {
              if (ApiService.isLoggedIn) {
                if (ApiService.isProvider) {
                  context.go('/sell');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Only providers can list books.'),
                      backgroundColor: Color(0xFFE74C3C),
                    ),
                  );
                }
              } else {
                LoginRequiredDialog.show(context);
              }
            },
          ),

          // 2. TRUST & BENEFITS BAR
          const HomeBenefitsBar(),

          // 3. ARCHIVE SUPERPOWER INTERACTIVE RAIL (AI & CUSTOM TOOLS)
          _buildSuperpowerFeatureRail(context),

          // 4. 3 CORE AI FEATURE CARDS ROW (Discover Match, Semester Planner, Shelf Scanner)
          if (MediaQuery.of(context).size.width >= 768)
            const HomeFeatureCardsRow(),

          // 5. BROWSE BY CATEGORY
          HomeAnimatedCategorySection(
            onCategorySelected: (category) {
              context.read<HomeBloc>().add(HomeCategorySelected(category));
              context.go('/browse?category=$category');
            },
          ),

          // 6. COMMUNITY CATALOG CAROUSEL
          HomeBookCarousel(
            title: 'Community Catalog',
            subtitle: 'Curated titles from The Tactile Archive community.',
            books: catalog,
          ),

          // 7. FREE COMMUNITY SWAPS SHELF (if available)
          if (freeSwaps.isNotEmpty)
            HomeBookCarousel(
              title: 'Free Community Swaps',
              subtitle: 'Exchange directly with local readers at ₹0.',
              books: freeSwaps,
            ),

          // 8. ACADEMIC & DEGREE TEXTBOOKS SHELF (if available)
          if (academicBooks.isNotEmpty)
            HomeBookCarousel(
              title: 'Academic & University Textbooks',
              subtitle: 'Save up to 70% with peer semester lending.',
              books: academicBooks,
            ),

          // 9. NEARBY EXCHANGE HUBS & SMART LOCKERS PREVIEW
          const HomeExchangeHubsPreview(),

          // 10. 4-STEP HOW IT WORKS PROCESS
          const HomeStepsSection(),

          // 11. WHY CHOOSE THE TACTILE ARCHIVE
          const HomeWhyChooseUsSection(),

          // 12. SELL OR LEND YOUR BOOKS CTA
          const HomeSellCtaSection(),

          // 13. READER PASSPORT & READING PROGRESS
          const HomeReaderPassportPreview(),

          // 14. COMMUNITY TESTIMONIALS
          const HomeTestimonials(),

          // 15. NEWSLETTER
          const HomeNewsletter(),

          // 15b. SUSTAINABILITY & CIRCULAR ECONOMY
          _buildSustainabilitySection(context),

          // 16. THE TACTILE ARCHIVE FOOTER
          const HomeFooter(),

          // 17. BOTTOM CLEARANCE FOR NAVBAR & FLOATING BUTTONS
          SizedBox(height: MediaQuery.of(context).padding.bottom + 85),
        ],
      ),
    );
  }

  // ------------------------------------------
  // The Tactile Archive Superpowers Quick-Access Rail
  // ------------------------------------------
  Widget _buildSuperpowerFeatureRail(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    final tools = [
      {
        'title': 'AI Mood Match',
        'subtitle': 'Discover your next read',
        'badge': 'AI MATCH',
        'icon': FontAwesomeIcons.brain,
        'iconColor': const Color(0xFF2E7D32),
        'iconBg': const Color(0xFFE8F5E9),
        'route': '/mood-match',
      },
      {
        'title': 'Shelf Scanner',
        'subtitle': 'Snap photo of bookshelf',
        'badge': 'VISION AI',
        'icon': FontAwesomeIcons.camera,
        'iconColor': const Color(0xFF1565C0),
        'iconBg': const Color(0xFFE3F2FD),
        'route': '/shelf-scanner',
      },
      {
        'title': 'Semester Study',
        'subtitle': 'Syllabus & exam planner',
        'badge': 'ACADEMIC',
        'icon': FontAwesomeIcons.graduationCap,
        'iconColor': const Color(0xFFF57F17),
        'iconBg': const Color(0xFFFFF8E1),
        'route': '/semester-planner',
      },
      {
        'title': 'Damage Inspector',
        'subtitle': 'AI book condition check',
        'badge': 'VERIFIED',
        'icon': FontAwesomeIcons.magnifyingGlass,
        'iconColor': const Color(0xFFC2185B),
        'iconBg': const Color(0xFFFCE4EC),
        'route': '/inspect-damage',
      },
      {
        'title': 'Free Book Swaps',
        'subtitle': '₹0 cashless exchanges',
        'badge': 'FREE',
        'icon': FontAwesomeIcons.arrowRightArrowLeft,
        'iconColor': DSColors.secondaryGreen,
        'iconBg': const Color(0xFFE0F2F1),
        'route': '/browse',
      },
      {
        'title': 'Exchange Hubs',
        'subtitle': 'Campus lockers & map',
        'badge': 'CAMPUS',
        'icon': FontAwesomeIcons.locationDot,
        'iconColor': DSColors.accentTerracotta,
        'iconBg': const Color(0xFFFBE9E7),
        'route': '/exchange-map',
      },
      {
        'title': 'Reader Passport',
        'subtitle': 'Streaks & green impact',
        'badge': 'PASSPORT',
        'icon': FontAwesomeIcons.passport,
        'iconColor': const Color(0xFF8B5CF6),
        'iconBg': const Color(0xFFF3E8FF),
        'route': '/passport',
      },
      {
        'title': 'Ask Archive AI',
        'subtitle': '24/7 literary concierge',
        'badge': '24/7 AI',
        'icon': FontAwesomeIcons.wandMagicSparkles,
        'iconColor': DSColors.deepForestGreen,
        'iconBg': const Color(0xFFE6F4EE),
        'route': '/archive-ai',
      },
    ];

    return Container(
      color: const Color(0xFFFDFBF7),
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 32 : 20,
        horizontal: isDesktop ? 24 : 16,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('✨', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 6),
                          Text(
                            'ARCHIVE SUPERPOWERS',
                            style: GoogleFonts.inter(
                              fontSize: isDesktop ? 11.5 : 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.3,
                              color: DSColors.accentTerracotta,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Signature Platform Features',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: isDesktop ? 28 : 20,
                          fontWeight: FontWeight.bold,
                          color: DSColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                  if (!isDesktop)
                    Text(
                      'Swipe 👉',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: DSColors.textMuted,
                      ),
                    ),
                ],
              ),
              SizedBox(height: isDesktop ? 18 : 14),
              SizedBox(
                height: isDesktop ? 154 : 124,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: tools.length,
                  separatorBuilder: (context, index) => SizedBox(width: isDesktop ? 16 : 12),
                  itemBuilder: (context, index) {
                    final item = tools[index];
                    return InkWell(
                      onTap: () {
                        final route = item['route'] as String;
                        if (route == '/archive-ai' || route == '/inspect-damage') {
                          context.push(route);
                        } else {
                          context.go(route);
                        }
                      },
                      borderRadius: BorderRadius.circular(DSRadius.card),
                      child: Container(
                        width: isDesktop ? 195 : 154,
                        padding: EdgeInsets.all(isDesktop ? 16 : 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(DSRadius.card),
                          border: Border.all(
                            color: DSColors.deepForestGreen.withValues(alpha: 0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDesktop ? 0.04 : 0.03),
                              blurRadius: isDesktop ? 10 : 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: isDesktop ? 44 : 36,
                                  height: isDesktop ? 44 : 36,
                                  decoration: BoxDecoration(
                                    color: item['iconBg'] as Color,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: FaIcon(
                                      item['icon'] as dynamic,
                                      color: item['iconColor'] as Color,
                                      size: isDesktop ? 18 : 15,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isDesktop ? 8 : 6,
                                    vertical: isDesktop ? 3 : 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (item['iconColor'] as Color).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(DSRadius.xs),
                                  ),
                                  child: Text(
                                    item['badge'] as String,
                                    style: GoogleFonts.inter(
                                      fontSize: isDesktop ? 9.5 : 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: item['iconColor'] as Color,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: isDesktop ? 14.5 : 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: DSColors.charcoal,
                                  ),
                                ),
                                SizedBox(height: isDesktop ? 4 : 2),
                                Text(
                                  item['subtitle'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: isDesktop ? 11.5 : 10,
                                    color: DSColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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


  // ------------------------------------------
  // The Circular Library & Book Sustainability Section
  // ------------------------------------------
  Widget _buildSustainabilitySection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    final impacts = [
      {
        'icon': Icons.recycling,
        'title': 'Circular Campus Economy',
        'desc': 'Textbooks pass from semester to semester rather than gathering dust or entering landfills.',
        'color': DSColors.deepForestGreen,
      },
      {
        'icon': Icons.auto_stories,
        'title': 'Preserving Print Heritage',
        'desc': 'Beloved editions, rare literature, and study notes find new appreciation with each custodian.',
        'color': DSColors.mutedTerracotta,
      },
      {
        'icon': Icons.location_on,
        'title': 'Neighborhood Hubs',
        'desc': 'Decentralized exchange lockers minimize packaging waste and long-haul shipping emissions.',
        'color': DSColors.secondaryGreen,
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 36 : 24,
        horizontal: isDesktop ? 32 : 16,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: EdgeInsets.all(isDesktop ? 36 : 22),
          decoration: BoxDecoration(
            color: DSColors.paperWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DSColors.softBorder),
            boxShadow: [
              BoxShadow(
                color: DSColors.charcoal.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
                    'CIRCULAR READING ECOSYSTEM',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: DSColors.mutedTerracotta,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'A Sustainable Second Life For Every Book',
                style: GoogleFonts.playfairDisplay(
                  fontSize: isDesktop ? 26 : 20,
                  fontWeight: FontWeight.w700,
                  color: DSColors.deepForestGreen,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Over 70% of college textbooks are discarded after a single term. The Tactile Archive keeps physical knowledge circulating.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: DSColors.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: impacts.map((item) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: _buildImpactCard(item),
                      ),
                    );
                  }).toList(),
                )
              else
                Column(
                  children: impacts.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _buildImpactCard(item),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImpactCard(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DSColors.warmIvory,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (item['color'] as Color).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                item['icon'] as IconData,
                size: 18,
                color: item['color'] as Color,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            item['title'] as String,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: DSColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item['desc'] as String,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: DSColors.textMuted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
