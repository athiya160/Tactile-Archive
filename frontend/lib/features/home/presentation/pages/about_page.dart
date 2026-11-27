import '../../../../core/design_system/tokens/ds_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/tactile_footer.dart';

class AboutPageV2 extends StatelessWidget {
  const AboutPageV2({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DSColors.warmIvory,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1100),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. HERO SECTION: OUR STORY
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth >= 800;

                        final leftText = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F4EE),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'ABOUT US',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: DSColors.deepForestGreen,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const SizedBox(height: 16),
                            Text(
                              'The Tactile Archive',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: DSColors.deepForestGreen,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'The Tactile Archive is a specialized peer-to-peer textbook rental, book borrowing, and community library marketplace. Designed specifically for students, academic researchers, and passionate readers, our platform enables users to list, borrow, rent, buy, and sell books within their local community — making education affordable and sustainable.',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                height: 1.6,
                                color: const Color(0xFF4A5568),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => context.go('/browse'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DSColors.deepForestGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Explore Marketplace',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );

                        final rightGraphic = Center(
                          child: Container(
                            height: 280,
                            constraints: const BoxConstraints(maxWidth: 360),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: const DecorationImage(
                                image: AssetImage('assets/images/hero.png'),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );

                        if (isDesktop) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(flex: 6, child: leftText),
                              const SizedBox(width: 40),
                              Expanded(flex: 5, child: rightGraphic),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            leftText,
                            const SizedBox(height: 32),
                            rightGraphic,
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 64),

                    // 2. WHAT WE BELIEVE IN SECTION
                    Text(
                      'Platform Highlights',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: DSColors.deepForestGreen,
                      ),
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossCount = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 550 ? 2 : 1);
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: constraints.maxWidth >= 900 ? 0.95 : 1.4,
                          children: [
                            _buildValueCard(
                              icon: Icons.school_outlined,
                              title: 'Student Semester Plans',
                              subtitle: 'Affordable academic textbook rentals tailored for engineering, medical, and degree courses.',
                            ),
                            _buildValueCard(
                              icon: Icons.swap_horiz_outlined,
                              title: 'Peer-to-Peer Sharing',
                              subtitle: 'Borrow, lend, or sell unused books directly to students and readers in your area.',
                            ),
                            _buildValueCard(
                              icon: Icons.auto_awesome_outlined,
                              title: '✨ AI Concierge Assistant',
                              subtitle: 'Smart AI reading recommendations and study guides based on your syllabus and goals.',
                            ),
                            _buildValueCard(
                              icon: Icons.verified_user_outlined,
                              title: 'Verified Quality',
                              subtitle: 'Inspected book conditions and secure local pickup points for safe transactions.',
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 64),

                    // 3. OUR JOURNEY SECTION
                    Text(
                      'How The Tactile Archive Works',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: DSColors.deepForestGreen,
                      ),
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossCount = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 550 ? 2 : 1);
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: constraints.maxWidth >= 900 ? 1.05 : 1.5,
                          children: [
                            _buildJourneyCard(
                              icon: Icons.search_outlined,
                              year: '01',
                              title: 'Discover Books',
                              subtitle: 'Search by course, ISBN, author, or category in your local community.',
                            ),
                            _buildJourneyCard(
                              icon: Icons.shopping_bag_outlined,
                              year: '02',
                              title: 'Rent or Buy',
                              subtitle: 'Choose flexible rental durations or buy second-hand at discounted rates.',
                            ),
                            _buildJourneyCard(
                              icon: Icons.location_on_outlined,
                              year: '03',
                              title: 'Safe Pickup',
                              subtitle: 'Meet at verified local pickup zones or arrange secure delivery.',
                            ),
                            _buildJourneyCard(
                              icon: Icons.monetization_on_outlined,
                              year: '04',
                              title: 'Earn as a Provider',
                              subtitle: 'List your old textbooks and earn passive income while helping fellow students.',
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 64),

                    // 4. JOIN OUR MISSION BOTTOM CTA BANNER
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFEDF2F7)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isDesktop = constraints.maxWidth >= 700;

                          final bannerContent = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Join Our Mission',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: DSColors.deepForestGreen,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Whether you're here to borrow, lend, or share — you're part of a movement that celebrates books and builds community.",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF4A5568),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          );

                          final button = ElevatedButton(
                            onPressed: () => context.go('/onboarding/user-type'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DSColors.deepForestGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Become a Member',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );

                          if (isDesktop) {
                            return Row(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF9F0),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFFFE8D6)),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.volunteer_activism_outlined, color: Color(0xFFD69E2E), size: 28),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(child: bannerContent),
                                const SizedBox(width: 24),
                                button,
                              ],
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF9F0),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.volunteer_activism_outlined, color: Color(0xFFD69E2E), size: 24),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(child: bannerContent),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(width: double.infinity, child: button),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 64),
                  ],
                ),
              ),
            ),
            const TactileFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildValueCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDF2F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFE6F4EE),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: DSColors.deepForestGreen),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF718096),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyCard({
    required IconData icon,
    required String year,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDF2F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F4EE),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: DSColors.deepForestGreen),
              ),
              const SizedBox(width: 10),
              Text(
                year,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: DSColors.deepForestGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF718096),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
