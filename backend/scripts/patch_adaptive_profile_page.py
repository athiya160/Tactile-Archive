import os
import re

path = r'frontend/lib/features/profile/presentation/pages/profile_page.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update _fetchProfileData to extract phone and student_profile
old_fetch_block = """            final data = res.data as Map<String, dynamic>;
            setState(() {
              _profileData['name'] = data['name'] ?? _profileData['name'];
              _profileData['email'] = data['email'] ?? _profileData['email'];
              if (data['stats'] != null) {
                _profileData['stats'] = data['stats'];
              }"""

new_fetch_block = """            final data = res.data as Map<String, dynamic>;
            setState(() {
              _profileData['name'] = data['name'] ?? _profileData['name'];
              _profileData['email'] = data['email'] ?? _profileData['email'];
              if (data['phone'] != null) {
                _profileData['phone'] = data['phone'];
              }
              if (data['student_profile'] != null) {
                _profileData['student_profile'] = data['student_profile'];
              }
              if (data['stats'] != null) {
                _profileData['stats'] = data['stats'];
              }"""

assert old_fetch_block in content, "old_fetch_block not found"
content = content.replace(old_fetch_block, new_fetch_block)

# 2. Update AppBar title and actions
old_appbar = """        title: Text(
          'Customer Profile',
          style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Switch to Provider Mode Button
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _isProviderMode = true),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storefront_outlined, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Provider Hub',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),"""

new_appbar = """        title: Text(
          ApiService.activeExperience == UserType.student ? 'Student Academic Profile' : 'Reader Profile',
          style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Adaptive Provider Mode / Activation Button
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: ApiService.providerEnabled
                  ? () => setState(() => _isProviderMode = true)
                  : () => _showProviderActivationDialog(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      ApiService.providerEnabled ? Icons.storefront_outlined : Icons.add_business_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ApiService.providerEnabled ? 'Provider Hub' : 'Become a Provider',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),"""

assert old_appbar in content, "old_appbar not found"
content = content.replace(old_appbar, new_appbar)

# 3. Update _buildOverviewTab to include switcher card & provider status card
old_overview_cards = """                  // Profile Header Card
                  _buildHeaderCard(name, email),
                  const SizedBox(height: 16),

                  // 4 Stat Counters Bar
                  _buildStatCountersBar(),"""

new_overview_cards = """                  // Profile Header Card
                  _buildHeaderCard(name, email),
                  const SizedBox(height: 16),

                  // 🔄 Adaptive Experience Mode Switcher Card
                  _buildExperienceSwitcherCard(),
                  const SizedBox(height: 16),

                  // 🏪 Provider Capability Status Card
                  _buildProviderStatusCard(),
                  const SizedBox(height: 16),

                  // 4 Stat Counters Bar
                  _buildStatCountersBar(),"""

assert old_overview_cards in content, "old_overview_cards not found"
content = content.replace(old_overview_cards, new_overview_cards)

# 4. Update _buildHeaderCard to display student academic details if in student mode
old_header_card = """  Widget _buildHeaderCard(String name, String email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFFF0F7F4),
            child: Text(
              name.isNotEmpty ? name[0] : 'A',
              style: GoogleFonts.playfairDisplay(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0D3B2E),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D3B2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Reader since 2026 • athiya160@gmail.com • +91 99864 74220',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF718096)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9F0),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 12, color: Color(0xFFD69E2E)),
                          const SizedBox(width: 4),
                          Text(
                            'Trusted Reader',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF975A16)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC6F6D5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Verified',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF22543D)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }"""

new_header_card = """  Widget _buildHeaderCard(String name, String email) {
    final isStudent = ApiService.activeExperience == UserType.student;
    final student = _profileData['student_profile'] as Map<String, dynamic>? ?? {};
    final college = student['college'] ?? student['university'];
    final course = student['course'] ?? student['degree'];
    final semester = student['semester'];
    final phone = _profileData['phone'] ?? '+91 99864 74220';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFFF0F7F4),
            child: Text(
              name.isNotEmpty ? name[0] : 'A',
              style: GoogleFonts.playfairDisplay(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0D3B2E),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D3B2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isStudent
                      ? 'Academic Member • $email • $phone'
                      : 'Reader since 2026 • $email • $phone',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF718096)),
                ),
                if (isStudent && (college != null || course != null)) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${college != null ? college : ""}${college != null && course != null ? " • " : ""}${course != null ? course : ""}${semester != null ? " ($semester)" : ""}',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF0D3B2E)),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isStudent ? const Color(0xFFF0F7F4) : const Color(0xFFFFF9F0),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isStudent ? const Color(0xFFC6F6D5) : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isStudent ? Icons.school : Icons.star,
                            size: 12,
                            color: isStudent ? const Color(0xFF0D3B2E) : const Color(0xFFD69E2E),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isStudent ? 'Student Account' : 'Reader Account',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isStudent ? const Color(0xFF0D3B2E) : const Color(0xFF975A16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (ApiService.providerEnabled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text(
                          '⭐ Provider Enabled',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC6F6D5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Verified',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF22543D)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }"""

assert old_header_card in content, "old_header_card not found"
content = content.replace(old_header_card, new_header_card)

# 5. Update _buildNavigationList to be adaptive
old_nav_list = """  Widget _buildNavigationList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildNavItem(Icons.shopping_bag_outlined, 'My Orders', () => context.push('/order-history')),
          _buildNavItem(Icons.book_outlined, 'My Rentals', () => context.push('/library?tab=1')),
          _buildNavItem(Icons.auto_stories_outlined, 'My Borrowed Books', () => context.push('/library?tab=0')),
          _buildNavItem(Icons.favorite_border, 'Favorites', () => context.push('/favorites')),
          _buildNavItem(Icons.school_outlined, 'Reading Plans', () => context.push('/plans')),
          _buildNavItem(Icons.location_on_outlined, 'Addresses', () => context.push('/delivery-address')),
          _buildNavItem(Icons.notifications_none, 'Notifications', () => context.push('/notifications')),
          _buildNavItem(Icons.storefront_outlined, 'Lender & Provider Operating Hub', () => setState(() => _isProviderMode = true)),
          _buildNavItem(Icons.support_agent_outlined, 'Support & Contact Concierge', () => context.push('/contact')),
          _buildNavItem(Icons.settings_outlined, 'Settings', () => context.push('/account-settings')),
          const Divider(height: 1),"""

new_nav_list = """  Widget _buildNavigationList() {
    final isStudent = ApiService.activeExperience == UserType.student;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildNavItem(Icons.shopping_bag_outlined, 'My Orders', () => context.push('/order-history')),
          _buildNavItem(Icons.book_outlined, 'My Rentals', () => context.push('/library?tab=1')),
          _buildNavItem(Icons.auto_stories_outlined, 'My Borrowed Books', () => context.push('/library?tab=0')),
          _buildNavItem(Icons.favorite_border, 'Favorites', () => context.push('/favorites')),
          if (isStudent) ...[
            _buildNavItem(Icons.school_outlined, 'Semester Study Planner', () => context.push('/semester-planner')),
            _buildNavItem(Icons.psychology_outlined, 'AI Study Assistant', () => context.push('/study-assistant')),
          ] else ...[
            _buildNavItem(Icons.auto_stories, 'Living Bookshelf', () => context.push('/library')),
            _buildNavItem(Icons.auto_awesome, 'AI Reading Concierge', () => context.push('/ai-concierge')),
          ],
          _buildNavItem(Icons.location_on_outlined, 'Addresses', () => context.push('/delivery-address')),
          _buildNavItem(Icons.notifications_none, 'Notifications', () => context.push('/notifications')),
          if (ApiService.providerEnabled)
            _buildNavItem(Icons.storefront_outlined, 'Lender & Provider Operating Hub', () => setState(() => _isProviderMode = true))
          else
            _buildNavItem(Icons.add_business_outlined, 'Become a Provider (Sell/Lend)', () => _showProviderActivationDialog()),
          _buildNavItem(Icons.support_agent_outlined, 'Support & Contact Concierge', () => context.push('/contact')),
          _buildNavItem(Icons.settings_outlined, 'Settings & Platform Experience', () => context.push('/account-settings')),
          const Divider(height: 1),"""

assert old_nav_list in content, "old_nav_list not found"
content = content.replace(old_nav_list, new_nav_list)

# 6. Add _buildExperienceSwitcherCard, _buildProviderStatusCard, _showProviderActivationDialog, and _buildFeatureBullet
helper_methods = """
  // 🔄 ADAPTIVE EXPERIENCE SWITCHER CARD
  Widget _buildExperienceSwitcherCard() {
    final active = ApiService.activeExperience;
    final isStudent = active == UserType.student;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF0D3B2E)),
                  const SizedBox(width: 8),
                  Text(
                    'Platform Experience Mode',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D3B2E),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7F4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC6F6D5)),
                ),
                child: Text(
                  isStudent ? '🎓 Student Mode' : '📖 Reader Mode',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D3B2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Switching experiences instantly adapts your dashboards, navigation, and tools while keeping all your orders, cart, and library intact.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF718096), height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Student Card Option
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: isStudent
                      ? null
                      : () async {
                          final success = await ApiService.switchExperience(UserType.student);
                          if (success && mounted) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Switched to Student Experience! Academic tools activated.'),
                                backgroundColor: const Color(0xFF0D3B2E),
                                action: SnackBarAction(
                                  label: 'Go to Dashboard',
                                  textColor: const Color(0xFFD69E2E),
                                  onPressed: () => context.go('/student'),
                                ),
                              ),
                            );
                          }
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isStudent ? const Color(0xFFF0F7F4) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isStudent ? const Color(0xFF0D3B2E) : const Color(0xFFE2E8F0),
                        width: isStudent ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('🎓', style: TextStyle(fontSize: 22)),
                            if (isStudent)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D3B2E),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'ACTIVE',
                                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Student Mode',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isStudent ? const Color(0xFF0D3B2E) : const Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Semester planner, syllabus, textbooks & study AI',
                          style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF718096)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Reader Card Option
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: !isStudent
                      ? null
                      : () async {
                          final success = await ApiService.switchExperience(UserType.reader);
                          if (success && mounted) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Switched to Reader Experience! Bookshelf & reading goals active.'),
                                backgroundColor: const Color(0xFF0D3B2E),
                                action: SnackBarAction(
                                  label: 'Go to Dashboard',
                                  textColor: const Color(0xFFD69E2E),
                                  onPressed: () => context.go('/reader'),
                                ),
                              ),
                            );
                          }
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: !isStudent ? const Color(0xFFF0F7F4) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !isStudent ? const Color(0xFF0D3B2E) : const Color(0xFFE2E8F0),
                        width: !isStudent ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('📖', style: TextStyle(fontSize: 22)),
                            if (!isStudent)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D3B2E),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'ACTIVE',
                                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Reader Mode',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: !isStudent ? const Color(0xFF0D3B2E) : const Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Living bookshelf, reading goals, concierge & discovery',
                          style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF718096)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🏪 PROVIDER CAPABILITY STATUS CARD
  Widget _buildProviderStatusCard() {
    final enabled = ApiService.providerEnabled;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFFFFBF0) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: enabled ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: enabled ? const Color(0xFFD97706).withValues(alpha: 0.12) : const Color(0xFFF0F7F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              enabled ? Icons.storefront_rounded : Icons.storefront_outlined,
              color: enabled ? const Color(0xFFB45309) : const Color(0xFF0D3B2E),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      enabled ? 'Provider Capabilities Active' : 'Sell or Lend Books',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1A202C)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: enabled ? const Color(0xFFC6F6D5) : const Color(0xFFEDF2F7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        enabled ? 'ACTIVE' : 'OPTIONAL',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: enabled ? const Color(0xFF22543D) : const Color(0xFF4A5568),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  enabled
                      ? 'You can list books, fulfill rental requests & earn.'
                      : 'Activate provider mode to list books without a second account.',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: enabled ? const Color(0xFF0D3B2E) : const Color(0xFFC85A32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: enabled
                ? () => setState(() => _isProviderMode = true)
                : () => _showProviderActivationDialog(),
            child: Text(
              enabled ? 'Open Hub' : 'Activate',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ✨ PROVIDER ACTIVATION BOTTOM SHEET DIALOG
  void _showProviderActivationDialog() {
    final businessController = TextEditingController(text: ApiService.userName ?? '');
    final phoneController = TextEditingController(text: _profileData['phone'] ?? '');
    bool isActivating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFFDFBF7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC85A32).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: Color(0xFFC85A32), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Activate Provider Mode',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0D3B2E),
                            ),
                          ),
                          Text(
                            'Sell & lend books with zero separate accounts',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF718096)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildFeatureBullet(Icons.inventory_2_outlined, 'List textbooks or novels in under 60 seconds'),
                      const SizedBox(height: 10),
                      _buildFeatureBullet(Icons.currency_rupee, 'Accept rental & sales earnings straight to your bank'),
                      const SizedBox(height: 10),
                      _buildFeatureBullet(Icons.swap_horiz, 'Keep your student or reader identity intact'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Store / Display Name (Optional)',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF2D3748)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: businessController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Campus Book Exchange',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E0)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Contact Phone Number',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF2D3748)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '+91 98765 43210',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E0)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D3B2E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: isActivating
                        ? null
                        : () async {
                            setModalState(() => isActivating = true);
                            final success = await ApiService.activateProvider(
                              businessName: businessController.text.trim().isNotEmpty
                                  ? businessController.text.trim()
                                  : null,
                              phone: phoneController.text.trim().isNotEmpty
                                  ? phoneController.text.trim()
                                  : null,
                            );
                            setModalState(() => isActivating = false);
                            if (mounted) {
                              Navigator.pop(ctx);
                              if (success) {
                                setState(() {
                                  _isProviderMode = true;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('🎉 Provider Mode Activated! Welcome to your Operating Hub.'),
                                    backgroundColor: Color(0xFF0D3B2E),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to activate provider mode. Please try again.'),
                                    backgroundColor: Color(0xFFE53E3E),
                                  ),
                                );
                              }
                            }
                          },
                    child: isActivating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Activate Provider Mode',
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBullet(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF0D3B2E)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF4A5568)),
          ),
        ),
      ],
    );
  }
"""

# Insert helper methods right before the closing brace of _ProfilePageState
last_brace = content.rfind('}')
assert last_brace != -1, "last brace not found"
content = content[:last_brace] + helper_methods + '\n}\n'

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESSFULLY PATCHED profile_page.dart!")
