path = r'frontend/lib/core/widgets/desktop_top_nav_bar.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 1. Update nav links
start_idx = None
end_idx = None
for i, line in enumerate(lines):
    if '// CENTER NAV LINKS' in line:
        start_idx = i
    if start_idx is not None and 'const SizedBox(width: 24),' in line and i > start_idx + 10:
        end_idx = i
        break

assert start_idx is not None and end_idx is not None, f"Nav links indices not found: {start_idx}, {end_idx}"

print(f"Replacing nav links lines {start_idx+1} to {end_idx+1}")

new_nav_chunk = """                    // CENTER NAV LINKS (Adaptive Experience)
                    Expanded(
                      child: ValueListenableBuilder<UserType>(
                        valueListenable: ApiService.experienceState,
                        builder: (context, activeExp, _) {
                          final isAuth = ApiService.isLoggedIn;
                          final isStudent = isAuth && activeExp == UserType.student;

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                if (isStudent) ...[
                                  _NavLink(
                                    label: 'Academic Home',
                                    isActive: location == '/student',
                                    onTap: () => context.go('/student'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Textbooks',
                                    isActive: location == '/browse',
                                    onTap: () => context.go('/browse'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Semester Planner',
                                    isActive: location == '/semester-planner',
                                    onTap: () => context.go('/semester-planner'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Study Assistant',
                                    isActive: location == '/study-assistant',
                                    onTap: () => context.go('/study-assistant'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Exchange Hubs',
                                    isActive: location == '/exchange-map',
                                    onTap: () => context.go('/exchange-map'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Sell / Lend',
                                    isActive: location.startsWith('/sell'),
                                    onTap: () {
                                      if (ApiService.providerEnabled) {
                                        context.go('/sell');
                                      } else {
                                        context.go('/profile');
                                      }
                                    },
                                  ),
                                ] else if (isAuth) ...[
                                  _NavLink(
                                    label: 'Reading Home',
                                    isActive: location == '/reader' || location == '/',
                                    onTap: () => context.go('/reader'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Discover',
                                    isActive: location == '/browse',
                                    onTap: () => context.go('/browse'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Bookshelf',
                                    isActive: location == '/library',
                                    onTap: () => context.go('/library'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Categories',
                                    isActive: location == '/categories',
                                    onTap: () => context.go('/categories'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Exchange Hubs',
                                    isActive: location == '/exchange-map',
                                    onTap: () => context.go('/exchange-map'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Sell / Lend',
                                    isActive: location.startsWith('/sell'),
                                    onTap: () {
                                      if (ApiService.providerEnabled) {
                                        context.go('/sell');
                                      } else {
                                        context.go('/profile');
                                      }
                                    },
                                  ),
                                ] else ...[
                                  _NavLink(
                                    label: 'Home',
                                    isActive: location == '/',
                                    onTap: () => context.go('/'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Browse',
                                    isActive: location == '/browse',
                                    onTap: () => context.go('/browse'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Categories',
                                    isActive: location == '/categories',
                                    onTap: () => context.go('/categories'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Exchange Hubs',
                                    isActive: location == '/exchange-map',
                                    onTap: () => context.go('/exchange-map'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'About Us',
                                    isActive: location == '/about',
                                    onTap: () => context.go('/about'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Contact',
                                    isActive: location == '/contact',
                                    onTap: () => context.go('/contact'),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
"""

lines = lines[:start_idx] + [new_nav_chunk] + lines[end_idx:]

# 2. Update popup menu
pop_start = None
pop_end = None
for i, line in enumerate(lines):
    if 'onSelected: (value) async {' in line:
        pop_start = i
    if pop_start is not None and ('],\n' in line and i > pop_start + 25):
        pop_end = i
        break

assert pop_start is not None and pop_end is not None, f"Popup menu indices not found: {pop_start}, {pop_end}"
print(f"Replacing popup menu lines {pop_start+1} to {pop_end+1}")

new_popup_chunk = """                                onSelected: (value) async {
                                  switch (value) {
                                    case 'profile':
                                      context.go('/profile');
                                      break;
                                    case 'switch_experience':
                                      final target = ApiService.activeExperience == UserType.student
                                          ? UserType.reader
                                          : UserType.student;
                                      await ApiService.switchExperience(target);
                                      if (context.mounted) {
                                        context.go(target == UserType.student ? '/student' : '/reader');
                                      }
                                      break;
                                    case 'provider':
                                      if (ApiService.providerEnabled) {
                                        context.go('/provider');
                                      } else {
                                        context.go('/profile');
                                      }
                                      break;
                                    case 'wishlist':
                                      context.go('/favorites');
                                      break;
                                    case 'orders':
                                      context.go('/order-history');
                                      break;
                                    case 'books':
                                      context.go('/library');
                                      break;
                                    case 'settings':
                                      context.go('/account-settings');
                                      break;
                                    case 'logout':
                                      await ApiService.logout();
                                      if (context.mounted) context.go('/');
                                      break;
                                  }
                                },
                                itemBuilder: (context) {
                                  final isStudent = ApiService.activeExperience == UserType.student;
                                  final isProv = ApiService.providerEnabled;

                                  return [
                                    _buildPopupItem(
                                      'profile',
                                      FontAwesomeIcons.user,
                                      isStudent ? 'Academic Profile' : 'Reader Profile',
                                    ),
                                    _buildPopupItem(
                                      'switch_experience',
                                      isStudent ? FontAwesomeIcons.bookOpen : FontAwesomeIcons.graduationCap,
                                      isStudent ? 'Switch to Reader Mode' : 'Switch to Student Mode',
                                    ),
                                    _buildPopupItem(
                                      'provider',
                                      FontAwesomeIcons.store,
                                      isProv ? 'Provider Operating Hub' : 'Become a Provider',
                                    ),
                                    const PopupMenuDivider(),
                                    _buildPopupItem('wishlist', FontAwesomeIcons.heart, 'Wishlist'),
                                    _buildPopupItem('orders', FontAwesomeIcons.receipt, 'My Orders'),
                                    _buildPopupItem('books', FontAwesomeIcons.book, isStudent ? 'My Course Books' : 'Living Bookshelf'),
                                    _buildPopupItem('settings', FontAwesomeIcons.gear, 'Account Settings'),
                                    const PopupMenuDivider(),
                                    _buildPopupItem('logout', FontAwesomeIcons.arrowRightFromBracket, 'Logout', isDestructive: true),
                                  ];
                                },
"""

lines = lines[:pop_start] + [new_popup_chunk] + lines[pop_end+1:]

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
print("SUCCESSFULLY PATCHED desktop_top_nav_bar.dart!")
