import sys

path = r'frontend/lib/core/widgets/mobile_top_nav_bar.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 1. Update build method of TactileMobileDrawer
drawer_build_start = None
for i, line in enumerate(lines):
    if 'class TactileMobileDrawer extends StatelessWidget' in line:
        drawer_build_start = i
        break

assert drawer_build_start is not None, "TactileMobileDrawer not found"

# Find from drawer_build_start to end of build method
start_vars = None
for i in range(drawer_build_start, len(lines)):
    if 'final isProvider = ApiService.isProvider;' in lines[i]:
        start_vars = i
        break

assert start_vars is not None, "start_vars not found"

# Let's inspect where drawer items list ends (around line 625)
end_drawer_list = None
for i in range(start_vars, len(lines)):
    if '// Auth Action' in lines[i]:
        end_drawer_list = i
        break

assert end_drawer_list is not None, "end_drawer_list not found"

new_drawer_body = """    final isProvider = ApiService.isProvider;
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
                color: const Color(0xFF0D3B2E),
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
                  color: const Color(0xFF0D3B2E).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF0D3B2E).withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isStudent ? Icons.auto_stories_outlined : Icons.school_outlined,
                      size: 16,
                      color: const Color(0xFF0D3B2E),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isStudent ? 'Switch to Reader Experience' : 'Switch to Student Experience',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0D3B2E),
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
                          color: const Color(0xFF0D3B2E),
                          borderRadius: BorderRadius.circular(6),
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
                      iconColor: const Color(0xFF0D3B2E),
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
                      badgeColor: const Color(0xFF00695C),
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
                      badgeColor: const Color(0xFFC85A32),
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
                      badgeColor: const Color(0xFF00695C),
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
                      badgeColor: const Color(0xFFC85A32),
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
"""

lines = lines[:start_vars] + [new_drawer_body] + lines[end_drawer_list:]

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
print("SUCCESSFULLY PATCHED mobile_top_nav_bar.dart!")
