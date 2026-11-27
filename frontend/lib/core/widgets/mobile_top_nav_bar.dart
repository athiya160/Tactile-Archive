import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/api_service.dart';
import '../tokens/app_tokens.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../features/cart/presentation/bloc/cart_state.dart';
import 'package:libri_flow/core/design_system/tokens/ds_colors.dart';
import 'package:libri_flow/core/design_system/tokens/ds_radius.dart';

class MobileTopNavBar extends StatelessWidget implements PreferredSizeWidget {
  const MobileTopNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(96);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE5DDD0).withValues(alpha: 0.7),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TIER 1: BRAND LOGO & ACTION ICONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                children: [
                  // Hamburger Menu
                  Builder(
                    builder: (scaffoldContext) {
                      return IconButton(
                        icon: const Icon(Icons.menu_rounded, color: Color(0xFF1B1E1B), size: 24),
                        tooltip: 'Archive Menu',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: () {
                          Scaffold.of(scaffoldContext).openDrawer();
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 4),

                  // Brand Identity
                  Expanded(
                    child: InkWell(
                      onTap: () => context.go('/'),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0D697).withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(DSRadius.sm),
                                border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.6)),
                              ),
                              alignment: Alignment.center,
                              child: const FaIcon(
                                FontAwesomeIcons.bookOpen,
                                color: Color(0xFFB8860B),
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'The Tactile Archive',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w800,
                                      color: DSColors.charcoal,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  Text(
                                    'PEER-TO-PEER BOOK MARKETPLACE',
                                    maxLines: 1,
                                    style: GoogleFonts.inter(
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w700,
                                      color: DSColors.antiqueGold,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Wishlist
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.heart, size: 17, color: Color(0xFF1B1E1B)),
                    tooltip: 'Wishlist',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () => context.go('/favorites'),
                  ),

                  // Cart with Live Badge
                  BlocBuilder<CartBloc, CartState>(
                    builder: (context, cartState) {
                      int count = 0;
                      if (cartState is CartLoaded) {
                        count = cartState.cart.items.length;
                      }

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.cartShopping, size: 17, color: Color(0xFF1B1E1B)),
                            tooltip: 'Cart',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            onPressed: () => context.go('/cart'),
                          ),
                          if (count > 0)
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE53E3E),
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  count > 9 ? '9+' : '$count',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(width: 4),

                  // User Avatar
                  ValueListenableBuilder<bool>(
                    valueListenable: ApiService.authState,
                    builder: (context, isLoggedIn, _) {
                      if (!isLoggedIn) {
                        return InkWell(
                          onTap: () => context.go('/login'),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE5DDD0),
                                width: 1.2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.person_outline_rounded,
                              size: 16,
                              color: Color(0xFF1B1E1B),
                            ),
                          ),
                        );
                      }

                      final initial = (ApiService.userName != null && ApiService.userName!.isNotEmpty)
                          ? ApiService.userName![0].toUpperCase()
                          : 'A';

                      return InkWell(
                        onTap: () => context.go('/profile'),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1B1E1B),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // TIER 2: TACTILE ARCHIVE SEARCH BAR WITH SMART SHELF SCANNER SHORTCUT
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DSRadius.md),
                  border: Border.all(color: DSColors.softBorder, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/browse'),
                      child: const Icon(Icons.search_rounded, color: Color(0xFF6B7280), size: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.go('/browse'),
                        child: Text(
                          'Search books, authors, courses, ISBN...',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF718096),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Quick Superpower Action: Vision Shelf Scanner
                    InkWell(
                      onTap: () => context.push('/shelf-scanner'),
                      borderRadius: BorderRadius.circular(DSRadius.sm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(DSRadius.sm),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.camera_alt_outlined, color: Color(0xFFB8860B), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'SCAN',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1B1E1B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TactileMobileDrawer extends StatelessWidget {
  const TactileMobileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final isAuth = ApiService.isLoggedIn;
    final userName = ApiService.userName ?? 'Athiya Tabassum';
    final activeExp = ApiService.activeExperience;
    final isStudent = activeExp == UserType.student;
    final hasProvider = ApiService.providerEnabled;

    return Drawer(
      backgroundColor: const Color(0xFFFDFBF7),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: DSColors.deepForestGreen,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFD69E2E).withValues(alpha: 0.25),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD69E2E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isStudent ? '🎓 Student Mode' : '📖 Reader Mode',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (hasProvider) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD69E2E).withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '⭐ Provider',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFDE68A),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Adaptive Experience Quick-Switch Bar
            if (isAuth)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: DSColors.deepForestGreen.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(DSRadius.md),
                  border: Border.all(color: DSColors.deepForestGreen.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isStudent ? Icons.auto_stories_outlined : Icons.school_outlined,
                      size: 16,
                      color: DSColors.deepForestGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isStudent ? 'Switch to Reader Experience' : 'Switch to Student Experience',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: DSColors.deepForestGreen,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        Navigator.pop(context);
                        final target = isStudent ? UserType.reader : UserType.student;
                        await ApiService.switchExperience(target);
                        if (context.mounted) {
                          context.go(target == UserType.student ? '/student' : '/reader');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: DSColors.deepForestGreen,
                          borderRadius: BorderRadius.circular(DSRadius.sm),
                        ),
                        child: Text(
                          'Switch',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Navigation Links
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  if (isStudent) ...[
                    // 1. STUDENT ACADEMIC & STUDY TOOLS
                    const _DrawerSectionHeader(title: 'Academic & Study Hub'),
                    _DrawerItem(
                      icon: Icons.school_outlined,
                      label: 'Student Academic Home',
                      isActive: location == '/student',
                      iconColor: DSColors.deepForestGreen,
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/student');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.assignment_outlined,
                      label: 'Semester Planner & Deadlines',
                      isActive: location == '/semester-planner',
                      badge: 'PLANNER',
                      badgeColor: const Color(0xFFF57F17),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/semester-planner');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.psychology_outlined,
                      label: 'AI Study Assistant',
                      isActive: location == '/study-assistant',
                      badge: 'AI STUDY',
                      badgeColor: const Color(0xFF2E7D32),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/study-assistant');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.document_scanner_outlined,
                      label: 'Smart Shelf Scanner',
                      isActive: location == '/shelf-scanner',
                      badge: 'VISION',
                      badgeColor: const Color(0xFF1565C0),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/shelf-scanner');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.auto_stories_outlined,
                      label: 'Textbook Discovery',
                      isActive: location == '/browse',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/browse');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.location_on_outlined,
                      label: 'Campus Exchange Hubs',
                      isActive: location == '/exchange-map',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/exchange-map');
                      },
                    ),

                    const Divider(height: 20, indent: 16, endIndent: 16),
                    const _DrawerSectionHeader(title: 'Marketplace & Sharing'),
                    _DrawerItem(
                      icon: Icons.storefront_outlined,
                      label: 'Peer Marketplace',
                      isActive: location == '/',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Free Book Swaps',
                      isActive: false,
                      badge: 'FREE',
                      badgeColor: DSColors.secondaryGreen,
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/browse?swap=true');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.sell_outlined,
                      label: 'Sell or Lend Textbooks',
                      isActive: location.startsWith('/sell'),
                      badge: 'EARN',
                      badgeColor: DSColors.accentTerracotta,
                      onTap: () {
                        Navigator.pop(context);
                        if (hasProvider) {
                          context.go('/sell');
                        } else {
                          context.go('/profile');
                        }
                      },
                    ),
                  ] else ...[
                    // 1. READER LIVING BOOKSHELF & DISCOVERY
                    const _DrawerSectionHeader(title: 'Living Bookshelf & Reading'),
                    _DrawerItem(
                      icon: Icons.home_outlined,
                      label: 'Reading Home',
                      isActive: location == '/reader' || location == '/',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/reader');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.auto_stories_outlined,
                      label: 'Browse Archive',
                      isActive: location == '/browse',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/browse');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.bookmarks_outlined,
                      label: 'Living Bookshelf',
                      isActive: location == '/library',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/library');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.auto_awesome,
                      label: 'AI Reading Concierge',
                      isActive: location == '/ai-concierge',
                      badge: 'CONCIERGE',
                      badgeColor: const Color(0xFFD69E2E),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/ai-concierge');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.psychology_outlined,
                      label: 'AI Mood Match & Ambience',
                      isActive: location == '/mood-match',
                      badge: 'AI MATCH',
                      badgeColor: const Color(0xFF2E7D32),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/mood-match');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.military_tech_outlined,
                      label: 'Reader Passport & Goals',
                      isActive: location == '/passport',
                      badge: 'REWARDS',
                      badgeColor: const Color(0xFF6B46C1),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/passport');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.location_on_outlined,
                      label: 'Community Exchange Hubs',
                      isActive: location == '/exchange-map',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/exchange-map');
                      },
                    ),

                    const Divider(height: 20, indent: 16, endIndent: 16),
                    const _DrawerSectionHeader(title: 'Marketplace & Capabilities'),
                    _DrawerItem(
                      icon: Icons.category_outlined,
                      label: 'Book Categories',
                      isActive: location == '/categories',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/categories');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Free Community Swaps',
                      isActive: false,
                      badge: 'FREE',
                      badgeColor: DSColors.secondaryGreen,
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/browse?swap=true');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.sell_outlined,
                      label: 'Sell or Lend Books',
                      isActive: location.startsWith('/sell'),
                      badge: 'EARN',
                      badgeColor: DSColors.accentTerracotta,
                      onTap: () {
                        Navigator.pop(context);
                        if (hasProvider) {
                          context.go('/sell');
                        } else {
                          context.go('/profile');
                        }
                      },
                    ),
                  ],

                  if (hasProvider) ...[
                    const Divider(height: 20, indent: 16, endIndent: 16),
                    const _DrawerSectionHeader(title: 'Provider Portal'),
                    _DrawerItem(
                      icon: Icons.storefront_outlined,
                      label: 'Provider Operating Hub',
                      isActive: location == '/provider',
                      iconColor: const Color(0xFF2E7D32),
                      badge: 'ACTIVE',
                      badgeColor: const Color(0xFF2E7D32),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/provider');
                      },
                    ),
                  ],

                  const Divider(height: 20, indent: 16, endIndent: 16),

                  // ACCOUNT & SETTINGS
                  const _DrawerSectionHeader(title: 'Account & Settings'),
                  _DrawerItem(
                    icon: Icons.person_outline,
                    label: isStudent ? 'Academic Profile' : 'Reader Profile',
                    isActive: location == '/profile',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/profile');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'Activity & Orders',
                    isActive: location == '/activity' || location == '/order-history',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/order-history');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Account & Platform Settings',
                    isActive: location == '/account-settings',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/account-settings');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline,
                    label: 'About The Tactile Archive',
                    isActive: location == '/about',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/about');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.mail_outline,
                    label: 'Contact & Support',
                    isActive: location == '/contact',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/contact');
                    },
                  ),
                ],
              ),
            ),
            // Auth Action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: isAuth
                  ? ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.logout, color: Color(0xFFE53E3E), size: 20),
                      title: Text(
                        'Sign Out',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE53E3E),
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        await ApiService.logout();
                        if (context.mounted) {
                          context.go('/');
                        }
                      },
                    )
                  : ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DSColors.deepForestGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DSRadius.md),
                        ),
                      ),
                      child: Text(
                        'Sign In / Register',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSectionHeader extends StatelessWidget {
  final String title;
  const _DrawerSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: const Color(0xFF718096),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color? iconColor;
  final String? badge;
  final Color? badgeColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.iconColor,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        leading: Icon(
          icon,
          size: 20,
          color: isActive
              ? DSColors.deepForestGreen
              : (iconColor ?? const Color(0xFF4A5568)),
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? DSColors.deepForestGreen : const Color(0xFF2D3748),
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (badgeColor ?? DSColors.accentTerracotta).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: (badgeColor ?? DSColors.accentTerracotta).withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: badgeColor ?? DSColors.accentTerracotta,
                  ),
                ),
              )
            : null,
        tileColor: isActive ? DSColors.deepForestGreen.withValues(alpha: 0.08) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: onTap,
      ),
    );
  }
}
