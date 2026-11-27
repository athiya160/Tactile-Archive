import '../../../../core/services/borrow_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/design_system/tokens/ds_colors.dart';
import '../../../../core/widgets/tactile_footer.dart';
import 'provider_dashboard_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isProviderMode = false;
  bool _isLoading = false;

  final Map<String, dynamic> _profileData = {
    'name': ApiService.userName ?? 'Athiya Tabassum',
    'email': 'athiya160@gmail.com',
    'reader_since': '2026',
    'stats': {
      'books_count': 0,
      'saved_count': 0,
      'exchanges_count': 0,
      'plans_count': 0,
    },
    'currently_reading': null,
    'ai_profile': {
      'favorite_genre': 'Curated Collection',
      'mood': 'Curious',
      'reading_pace': 'Moderate (30 min/day)',
    },
    'passport': {
      'tier': '🌱 New Reader',
      'member_id': 'LF-2026-0001',
      'books_completed': 0,
      'books_reused': 0,
      'exchanges': 0,
      'money_saved': '₹0',
    },
    'passport_badges': [
      {'icon': '🏆', 'title': 'Early Reader'},
      {'icon': '🔄', 'title': 'Community Builder'},
      {'icon': '📚', 'title': 'Book Explorer'},
    ]
  };

  List<Map<String, dynamic>> _activityFeed = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _fetchProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    try {
      await Future.wait([
        ApiService.get('/users/me/profile').timeout(const Duration(seconds: 3)).then((res) {
          if (res.statusCode == 200 && res.data != null && mounted) {
            final data = res.data as Map<String, dynamic>;
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
              }
              if (data['currently_reading'] != null) {
                _profileData['currently_reading'] = data['currently_reading'];
              }
              if (data['passport'] != null) {
                _profileData['passport'] = data['passport'];
              }
            });
          }
        }).catchError((_) {}),
        ApiService.get('/activity/feed').timeout(const Duration(seconds: 3)).then((actRes) {
          if (actRes.statusCode == 200 && actRes.data is List && mounted) {
            setState(() {
              _activityFeed = (actRes.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
            });
          }
        }).catchError((_) {}),
        ApiService.get('/gamification/passport').timeout(const Duration(seconds: 3)).then((passRes) {
          if (passRes.statusCode == 200 && passRes.data != null && mounted) {
            final passData = passRes.data as Map<String, dynamic>;
            setState(() {
              if (passData['books_borrowed_count'] != null) {
                _profileData['stats']['books_count'] = passData['books_borrowed_count'];
              }
            });
          }
        }).catchError((_) {}),
      ]);
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If in Provider Mode, render Provider Operating Hub directly with toggle back
    if (_isProviderMode) {
      return ProviderDashboardPage(
        onSwitchToReader: () => setState(() => _isProviderMode = false),
      );
    }

    final name = _profileData['name'] ?? 'Athiya Tabassum';
    final email = _profileData['email'] ?? 'athiya160@gmail.com';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F6),
      appBar: AppBar(
        backgroundColor: DSColors.forestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          tooltip: 'Back to Home',
          onPressed: () => context.go('/'),
        ),
        title: Text(
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
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 18),
              tooltip: 'Account Settings',
              onPressed: () => context.push('/account-settings'),
            ),
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD69E2E),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Activity'),
            Tab(text: 'Passport'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: DSColors.forestGreen))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(name, email),
                _buildActivityTab(),
                _buildPassportTab(),
              ],
            ),
    );
  }

  // 1. OVERVIEW TAB
  Widget _buildOverviewTab(String name, String email) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header Card
                  _buildHeaderCard(name, email),
                  const SizedBox(height: 16),

                  // 🔄 Adaptive Experience Mode Switcher Card
                  _buildExperienceSwitcherCard(),
                  const SizedBox(height: 16),

                  // 🏪 Provider Capability Status Card
                  _buildProviderStatusCard(),
                  const SizedBox(height: 16),

                  // 4 Stat Counters Bar
                  _buildStatCountersBar(),
                  const SizedBox(height: 20),

                  // 🤝 Active Borrow & Community Requests Card
                  _buildBorrowRequestsCard(),
                  const SizedBox(height: 16),

                  // 📖 Currently Reading Card
                  _buildCurrentlyReadingCard(),
                  const SizedBox(height: 16),

                  // 🤖 Your AI Reading Profile Card
                  _buildAIProfileCard(),
                  const SizedBox(height: 16),

                  // 🏆 Reader Passport Preview Card
                  _buildPassportPreviewCard(),
                  const SizedBox(height: 24),

                  // Navigation Links List
                  _buildNavigationList(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          const TactileFooter(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(String name, String email) {
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
        border: Border.all(color: DSColors.softBorder),
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
                    '${college ?? ""}${college != null && course != null ? " • " : ""}${course ?? ""}${semester != null ? " ($semester)" : ""}',
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
  }

  Widget _buildStatCountersBar() {
    final stats = _profileData['stats'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DSColors.softBorder),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatItem('📚 ${stats['books_count'] ?? 0}', 'Books')),
          _buildDivider(),
          Expanded(child: _buildStatItem('❤️ ${stats['saved_count'] ?? 0}', 'Saved')),
          _buildDivider(),
          Expanded(child: _buildStatItem('🔄 ${stats['exchanges_count'] ?? 0}', 'Exchanges')),
          _buildDivider(),
          Expanded(child: _buildStatItem('🎓 ${stats['plans_count'] ?? 0}', 'Plans')),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E)),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF718096)),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 24, width: 1, color: const Color(0xFFEDF2F7));
  }


  // 🤝 ACTIVE BORROW REQUESTS CARD
  Widget _buildBorrowRequestsCard() {
    final requests = BorrowService.getAllRequests();
    if (requests.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DSColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.handshake_outlined, size: 18, color: Color(0xFF0D3B2E)),
                  const SizedBox(width: 8),
                  Text(
                    'My Borrow Requests',
                    style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7F4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${requests.length} Active',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...requests.map((req) {
            final isPending = req.stage == BorrowStage.pending;
            final isAccepted = req.stage == BorrowStage.accepted;

            final statusColor = isPending
                ? const Color(0xFFD97706)
                : isAccepted
                    ? const Color(0xFF166534)
                    : const Color(0xFF2563EB);

            final statusBg = isPending
                ? const Color(0xFFFFFBEB)
                : isAccepted
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFEFF6FF);

            final statusLabel = isPending
                ? 'Awaiting Owner Review'
                : isAccepted
                    ? 'Owner Accepted! Address Ready'
                    : 'Handover Confirmed';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DSColors.softBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D3B2E),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.book, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.bookTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1A202C)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Owner: ${req.ownerName} • ${req.durationDays} Days',
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096)),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusLabel,
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.push('/buy-now-checkout', extra: {
                        'mode': 'borrow',
                        'rentalDays': req.durationDays,
                      });
                    },
                    child: Text(
                      isAccepted ? 'Proceed →' : 'View',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

    // 📖 CURRENTLY READING CARD
  Widget _buildCurrentlyReadingCard() {
    final cur = _profileData['currently_reading'] as Map<String, dynamic>? ?? {};
    final title = cur['title'] ?? 'Atomic Habits';
    final progress = (cur['progress'] as num?)?.toDouble() ?? 0.64;
    final progressText = cur['progress_text'] ?? '64% complete';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DSColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📖', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'Currently Reading',
                style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 44,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D3B2E),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Icon(Icons.book, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      progressText,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2E7D32)),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xFFEDF2F7),
                        color: const Color(0xFF0D3B2E),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => context.push('/reading-plan?title=$title'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Continue Reading →',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🤖 YOUR AI READING PROFILE CARD
  Widget _buildAIProfileCard() {
    final ai = _profileData['ai_profile'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DSColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'Your AI Reading Profile',
                style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAIProfileRow('Favorite:', ai['favorite_genre'] ?? 'Fiction'),
          _buildAIProfileRow('Mood:', ai['mood'] ?? 'Curious'),
          _buildAIProfileRow('Reading pace:', ai['reading_pace'] ?? 'Moderate'),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => context.push('/ai-concierge'),
            icon: const Icon(Icons.auto_awesome, size: 14),
            label: const Text('Improve Recommendations'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0D3B2E),
              side: const BorderSide(color: Color(0xFF0D3B2E)),
              minimumSize: const Size(double.infinity, 38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label ', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4A5568))),
          Text(value, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF718096))),
        ],
      ),
    );
  }

  // 🏆 READER PASSPORT PREVIEW CARD
  Widget _buildPassportPreviewCard() {
    final badges = (_profileData['passport_badges'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DSColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'Reader Passport',
                    style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E)),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _tabController.animateTo(2),
                child: Text(
                  'View Passport →',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: badges.map((b) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7F4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFC6F6D5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(b['icon'] ?? '🥇'),
                    const SizedBox(width: 6),
                    Text(
                      b['title'] ?? '',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // GROUPED NAVIGATION LIST
  Widget _buildNavigationList() {
    final isStudent = ApiService.activeExperience == UserType.student;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DSColors.softBorder),
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
          const Divider(height: 1),
          ListTile(
            onTap: () async {
              await ApiService.logout();
              if (mounted) context.go('/');
            },
            leading: const Icon(Icons.logout, color: Color(0xFFDC2626), size: 20),
            title: Text('Log Out', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFDC2626))),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFFA0AEC0)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Icon(icon, color: const Color(0xFF0D3B2E), size: 20),
          title: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF2D3748))),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFFA0AEC0), size: 18),
        ),
        const Divider(height: 1, indent: 52, color: Color(0xFFF1F5F9)),
      ],
    );
  }

  // 2. ACTIVITY TAB
  Widget _buildActivityTab() {
    final activities = _activityFeed.isNotEmpty
        ? _activityFeed
        : [
            {
              'icon': '📚',
              'title': 'Borrowed',
              'book_title': 'Atomic Habits',
              'description': 'Borrowed from community library (14-day cycle).',
              'time_ago': '2 days ago',
            },
            {
              'icon': '🔄',
              'title': 'Exchanged',
              'book_title': 'Clean Code',
              'description': 'Completed physical swap at Indiranagar Tactile Hub.',
              'time_ago': '5 days ago',
            },
            {
              'icon': '❤️',
              'title': 'Saved',
              'book_title': 'Deep Work',
              'description': 'Added to personal wishlist shelf.',
              'time_ago': '1 week ago',
            },
            {
              'icon': '💰',
              'title': 'Purchased',
              'book_title': 'The Pragmatic Programmer',
              'description': 'Purchased verified collector hardcover edition.',
              'time_ago': '2 weeks ago',
            },
          ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Activity',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D3B2E),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7F4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Live Feed',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0D3B2E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...activities.map((act) {
                final icon = act['icon'] as String? ?? '📚';
                final title = act['title'] as String? ?? 'Activity';
                final bookTitle = act['book_title'] as String? ?? '';
                final desc = act['description'] as String? ?? '';
                final timeAgo = act['time_ago'] as String? ?? act['timestamp'] as String? ?? 'Recently';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: DSColors.softBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F7F4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFC6F6D5)),
                        ),
                        child: Center(
                          child: Text(icon, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        title,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0D3B2E),
                                        ),
                                      ),
                                      if (bookTitle.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '• $bookTitle',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF2D3748),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  timeAgo,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFFA0AEC0),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              desc,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF718096),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // 3. PASSPORT TAB
  Widget _buildPassportTab() {
    final passport = _profileData['passport'] as Map<String, dynamic>? ?? {};
    final stats = _profileData['stats'] as Map<String, dynamic>? ?? {};

    final booksCount = stats['books_count'] ?? 24;
    final exchangesCount = passport['exchanges'] ?? stats['exchanges_count'] ?? 8;
    final completedCount = passport['books_completed'] ?? 17;
    final moneySaved = passport['money_saved'] ?? '₹3,200';
    final reusedCount = passport['books_reused'] ?? 12;

    final badges = [
      {
        'icon': '🏆',
        'title': 'Early Reader',
        'desc': 'Founding member of Tactile Archive',
        'date': 'Jan 2026',
        'earned': true,
      },
      {
        'icon': '🔄',
        'title': 'Community Builder',
        'desc': 'Completed 5+ verified hub exchanges',
        'date': 'Feb 2026',
        'earned': true,
      },
      {
        'icon': '📚',
        'title': 'Book Explorer',
        'desc': 'Read across 5 distinct genres',
        'date': 'Feb 2026',
        'earned': true,
      },
      {
        'icon': '🎓',
        'title': 'Study Streak',
        'desc': '14-day study plan adherence',
        'date': 'Mar 2026',
        'earned': true,
      },
      {
        'icon': '🌱',
        'title': 'Book Reuser',
        'desc': 'Reused 10+ books within community',
        'date': 'Mar 2026',
        'earned': true,
      },
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Passport Hero Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D3B2E), Color(0xFF1B4332), Color(0xFF2D6A4F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D3B2E).withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.verified, color: Color(0xFFD69E2E), size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        'READER PASSPORT',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD69E2E).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFD69E2E)),
                              ),
                              child: Text(
                                '⭐ Trusted Reader',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFDE68A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _profileData['name'] ?? 'Athiya Tabassum',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Member #${passport['member_id'] ?? 'LF-2026-0842'} • Verified Tactile Scholar',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: _buildPassportStat('📚 $booksCount', 'Books')),
                              Container(width: 1, height: 24, color: Colors.white24),
                              Expanded(child: _buildPassportStat('🔄 $exchangesCount', 'Exchanges')),
                              Container(width: 1, height: 24, color: Colors.white24),
                              Expanded(child: _buildPassportStat('📖 $completedCount', 'Completed')),
                              Container(width: 1, height: 24, color: Colors.white24),
                              Expanded(child: _buildPassportStat('💰 $moneySaved', 'Saved')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Community Impact Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: DSColors.softBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('🌱', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              'Community & Environmental Impact',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0D3B2E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 500) {
                              return Column(
                                children: [
                                  _buildImpactTile('$reusedCount', 'Books Reused', 'Diverted from waste', const Color(0xFF2E7D32)),
                                  const SizedBox(height: 10),
                                  _buildImpactTile('$exchangesCount', 'Hub Swaps', 'Zero-shipping impact', const Color(0xFF0D3B2E)),
                                  const SizedBox(height: 10),
                                  _buildImpactTile(moneySaved, 'Total Savings', 'Community circulation', const Color(0xFF975A16)),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(
                                  child: _buildImpactTile('$reusedCount', 'Books Reused', 'Diverted from waste', const Color(0xFF2E7D32)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildImpactTile('$exchangesCount', 'Hub Swaps', 'Zero-shipping impact', const Color(0xFF0D3B2E)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildImpactTile(moneySaved, 'Total Savings', 'Community circulation', const Color(0xFF975A16)),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Earned Badges Section
                  Text(
                    'Earned Badges (5)',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D3B2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...badges.map((b) => _buildBadgeRow(b)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          const TactileFooter(),
        ],
      ),
    );
  }

  Widget _buildPassportStat(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildImpactTile(String value, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DSColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748)),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF718096)),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeRow(Map<String, dynamic> badge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DSColors.softBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7F4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC6F6D5)),
            ),
            child: Center(
              child: Text(badge['icon'] as String, style: const TextStyle(fontSize: 20)),
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
                      badge['title'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0D3B2E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: DSColors.softBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge['date'] as String,
                        style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF4A5568)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  badge['desc'] as String,
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096)),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Color(0xFF38A169), size: 18),
        ],
      ),
    );
  }

  // 🔄 ADAPTIVE EXPERIENCE SWITCHER CARD
  Widget _buildExperienceSwitcherCard() {
    final active = ApiService.activeExperience;
    final isStudent = active == UserType.student;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DSColors.softBorder),
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
                        color: isStudent ? const Color(0xFF0D3B2E) : DSColors.softBorder,
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
                        color: !isStudent ? const Color(0xFF0D3B2E) : DSColors.softBorder,
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
        border: Border.all(color: enabled ? const Color(0xFFFDE68A) : DSColors.softBorder),
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
                      color: DSColors.softBorder,
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
                    border: Border.all(color: DSColors.softBorder),
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
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              if (success) {
                                setState(() {
                                  _isProviderMode = true;
                                });
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('🎉 Provider Mode Activated! Welcome to your Operating Hub.'),
                                    backgroundColor: Color(0xFF0D3B2E),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(ctx).showSnackBar(
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

}
