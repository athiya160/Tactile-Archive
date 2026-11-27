import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/google_auth_service.dart';
import '../../../../core/design_system/design_system.dart';

class AuthLandingPage extends StatelessWidget {
  const AuthLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.warmIvory,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 1. TOP HEADER & LOGO
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                color: DSColors.paperWhite,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1300),
                    child: LayoutBuilder(
                      builder: (context, headerConstraints) {
                        final isMobile = headerConstraints.maxWidth < 1050;
                        if (isMobile) {
                          return Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_rounded, color: DSColors.deepForestGreen),
                                onPressed: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go('/');
                                  }
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Home',
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.menu_book, color: DSColors.deepForestGreen, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'The Tactile Archive',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: DSColors.deepForestGreen,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.push('/login'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  minimumSize: Size.zero,
                                ),
                                child: Text(
                                  'Log In',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: DSColors.deepForestGreen,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton(
                                onPressed: () => context.push('/register'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DSColors.deepForestGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                ),
                                child: Text(
                                  'Sign Up',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.menu_book, color: DSColors.deepForestGreen, size: 24),
                                const SizedBox(width: 10),
                                Text(
                                  'The Tactile Archive',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: DSColors.deepForestGreen,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Flexible(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildNavLink(context, 'Browse', '/browse'),
                                    _buildNavLink(context, 'Categories', '/categories'),
                                    _buildNavLink(context, 'Sell', '/sell'),
                                    _buildNavLink(context, 'About Us', '/about'),
                                    _buildNavLink(context, 'Contact', '/contact'),
                                    const SizedBox(width: 16),
                                    TextButton(
                                      onPressed: () => context.push('/login'),
                                      child: Text(
                                        'Log In',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: DSColors.deepForestGreen,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => context.push('/register'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: DSColors.deepForestGreen,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                      ),
                                      child: Text(
                                        'Sign Up',
                                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // 2. HERO CONTENT SECTION
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth >= 900;

                      final textColumn = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: DSColors.softMint.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: DSColors.deepForestGreen.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lock_open_rounded, size: 14, color: DSColors.deepForestGreen),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'AUTHENTICATION PORTAL',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                      color: DSColors.deepForestGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            'One world.\nDifferent ways to read.',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: isDesktop ? 44 : 32,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              color: DSColors.deepForestGreen,
                            ),
                          ),
                          const SizedBox(height: 14),

                          Text(
                            'Discover textbooks, build your personal bookshelf, or share physical books with zero deposit and community escrow protection.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: DSColors.textLight,
                              height: 1.55,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Experience Selection Cards Preview
                          Text(
                            'HOW WOULD YOU LIKE TO BEGIN?',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: DSColors.textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 12),

                          _buildExperienceQuickCard(
                            context: context,
                            title: "I'm a Student",
                            subtitle: 'Study, discover, manage syllabus, and track academic reading.',
                            icon: Icons.school_rounded,
                            badge: 'Study Mode',
                            color: DSColors.deepForestGreen,
                            onTap: () => context.push('/register', extra: UserType.student),
                          ),
                          const SizedBox(height: 10),

                          _buildExperienceQuickCard(
                            context: context,
                            title: "I'm a Reader",
                            subtitle: 'Discover books, buy, rent, borrow, and build your personal library.',
                            icon: Icons.auto_stories_rounded,
                            badge: 'Reading Mode',
                            color: const Color(0xFF2B6CB0),
                            onTap: () => context.push('/register', extra: UserType.reader),
                          ),
                          const SizedBox(height: 24),

                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => GoogleAuthService.signInWithGoogle(context),
                                icon: const FaIcon(FontAwesomeIcons.google, size: 15, color: Color(0xFFEA4335)),
                                label: Text(
                                  'Continue with Google',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: DSColors.charcoal,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DSColors.paperWhite,
                                  foregroundColor: DSColors.charcoal,
                                  minimumSize: const Size(0, 48),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
                                  side: const BorderSide(color: DSColors.softBorder, width: 1.2),
                                  elevation: 1,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => context.push('/login'),
                                icon: const Icon(Icons.login_rounded, size: 16),
                                label: Text(
                                  'Sign In to Account',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DSColors.deepForestGreen,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 48),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
                                  elevation: 2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => context.go('/browse'),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Or explore catalog as guest →',
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: DSColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );

                      final imagePreview = Container(
                        height: isDesktop ? 420 : 360,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(DSRadius.card),
                          boxShadow: [
                            BoxShadow(
                              color: DSColors.deepForestGreen.withValues(alpha: 0.12),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [DSColors.deepForestGreen, DSColors.secondaryGreen],
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Soft book backdrop
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(DSRadius.card),
                                child: Opacity(
                                  opacity: 0.22,
                                  child: Image.network(
                                    'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=800',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                  ),
                                ),
                              ),
                            ),
                            // Content overlay
                            Padding(
                              padding: EdgeInsets.all(isDesktop ? 28 : 20),
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                          ),
                                          child: Text(
                                            'THE TACTILE ARCHIVE',
                                            style: GoogleFonts.inter(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.1,
                                              color: const Color(0xFFF6E05E),
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.auto_stories, color: Colors.white70, size: 20),
                                      ],
                                    ),
                                    SizedBox(height: isDesktop ? 40 : 24),
                                    Text(
                                      'A Single Account.\nTwo Reading Worlds.',
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Seamlessly switch between Academic study tracking and your personal leisure bookshelf without losing progress.',
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        color: Colors.white.withValues(alpha: 0.85),
                                        height: 1.45,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(DSRadius.md),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.verified, size: 15, color: Color(0xFF48BB78)),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              '100% Escrow Protected Guarantee',
                                              style: GoogleFonts.inter(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (isDesktop) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 6, child: textColumn),
                            const SizedBox(width: 40),
                            Expanded(flex: 5, child: imagePreview),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          textColumn,
                          const SizedBox(height: 32),
                          imagePreview,
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExperienceQuickCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String badge,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DSRadius.md),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DSColors.paperWhite,
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(color: DSColors.softBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: DSColors.deepForestGreen,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(DSRadius.xs),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 11.5, color: DSColors.textMuted, height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFA0AEC0)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavLink(BuildContext context, String title, String path) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: InkWell(
        onTap: () => context.go(path),
        child: Text(
          title,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: DSColors.textLight),
        ),
      ),
    );
  }
}
