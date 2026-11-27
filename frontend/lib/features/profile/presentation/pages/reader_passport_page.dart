import '../../../../core/design_system/tokens/ds_radius.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/design_system/tokens/ds_colors.dart';
import '../../../../core/widgets/tactile_footer.dart';

class ReaderPassportPage extends StatefulWidget {
  const ReaderPassportPage({super.key});

  @override
  State<ReaderPassportPage> createState() => _ReaderPassportPageState();
}

class _ReaderPassportPageState extends State<ReaderPassportPage> {
  bool _isLoading = true;

  final Map<String, dynamic> _passportData = {
    'user_name': ApiService.userName ?? 'Reader',
    'passport_level': 'Reader Member',
    'reading_streak_days': 0,
    'books_read_count': 0,
    'books_borrowed_count': 0,
    'books_shared_count': 0,
    'books_exchanged_count': 0,
    'community_rating': '5.0 ★★★★★',
    'verified_handoffs': 0,
    'favorite_genres': ['Curated Collection'],
    'badges': [
      {
        'id': '1',
        'title': 'First Book',
        'icon': '🏅',
        'description': 'Read or listed your first book in the archive.',
        'earned_at': 'Unlocked',
        'isUnlocked': true,
      },
      {
        'id': '2',
        'title': 'First Exchange',
        'icon': '🤝',
        'description': 'Completed your 1st physical hub swap.',
        'earned_at': 'Unlocked',
        'isUnlocked': true,
      },
      {
        'id': '3',
        'title': 'Community Contributor',
        'icon': '🌿',
        'description': 'Shared 5+ books with fellow readers.',
        'earned_at': 'Unlocked',
        'isUnlocked': true,
      },
      {
        'id': '4',
        'title': 'Archive Explorer',
        'icon': '🗺️',
        'description': 'Visited 3+ exchange hubs & used Shelf Scanner.',
        'earned_at': 'Unlocked',
        'isUnlocked': true,
      },
      {
        'id': '5',
        'title': 'Reading Streak',
        'icon': '🔥',
        'description': 'Maintained a 7+ day consecutive reading streak.',
        'earned_at': 'Unlocked',
        'isUnlocked': true,
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _fetchPassportData();
  }

  Future<void> _fetchPassportData() async {
    try {
      final res = await ApiService.get('/gamification/passport');
      if (res.statusCode == 200 && res.data != null) {
        setState(() {
          _passportData.addAll(res.data as Map<String, dynamic>);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.background,
      appBar: AppBar(
        backgroundColor: DSColors.forestGreen,
        foregroundColor: Colors.white,
        title: Text(
          'Reader Passport & Credentials',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: DSColors.forestGreen))
          : SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                    child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // IDENTITY NOTICE CALLOUT
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: DSColors.softMint,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: DSColors.forestGreen.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const FaIcon(FontAwesomeIcons.circleInfo, size: 14, color: DSColors.forestGreen),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'The Tactile Archive Reader Passport is your community reading credential & activity record. It is NOT an official government ID.',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DSColors.forestGreen),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // PASSPORT CARD & ACTIVITY BREAKDOWN
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isDesktop = constraints.maxWidth >= 900;

                          if (isDesktop) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 5, child: _buildPassportCard()),
                                const SizedBox(width: 28),
                                Expanded(flex: 7, child: _buildActivityDetailsCard()),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              _buildPassportCard(),
                              const SizedBox(height: 24),
                              _buildActivityDetailsCard(),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 36),

                      // ACHIEVEMENTS BADGES SECTION
                      Text(
                        'Earned Achievement Badges',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: DSColors.forestGreen,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Badges unlocked automatically through real reading activity & exchange contributions.',
                        style: GoogleFonts.inter(fontSize: 13, color: DSColors.textLight),
                      ),
                      const SizedBox(height: 20),

                      _buildBadgesGrid(),
                    ],
                  ),
                ),
              ),
            ),
            const TactileFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildPassportCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: DSColors.forestGreen,
        borderRadius: BorderRadius.circular(DSRadius.card),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DSColors.warmGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: DSColors.warmGold),
                ),
                child: Text(
                  'MEMBER PASSPORT',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: DSColors.warmGold,
                  ),
                ),
              ),
              const FaIcon(FontAwesomeIcons.idCard, color: DSColors.warmGold, size: 24),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _passportData['user_name'] as String,
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            _passportData['passport_level'] as String,
            style: GoogleFonts.inter(fontSize: 14, color: DSColors.warmGold, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPassportStat('🔥 Streak', '${_passportData['reading_streak_days']} Days'),
              _buildPassportStat('📖 Read', '${_passportData['books_read_count']} Books'),
              _buildPassportStat('⭐ Rating', '${_passportData['community_rating']}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassportStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildActivityDetailsCard() {
    final genres = _passportData['favorite_genres'] as List<String>? ?? [];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Community Activity & Stats',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: DSColors.forestGreen,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _buildMetricTile('Books Borrowed', '${_passportData['books_borrowed_count']} Volumes')),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricTile('Books Shared', '${_passportData['books_shared_count']} Listed')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricTile('Completed Swaps', '${_passportData['books_exchanged_count']} Exchanged')),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricTile('Verified Handoffs', '${_passportData['verified_handoffs']} At Hubs')),
            ],
          ),

          const SizedBox(height: 24),
          Text(
            'Favorite Genres',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: DSColors.forestGreen),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: genres.map((g) {
              return Chip(
                label: Text(g),
                backgroundColor: DSColors.softMint,
                side: BorderSide.none,
                labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.forestGreen),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DSColors.background,
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: DSColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: DSColors.textMuted)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: DSColors.forestGreen)),
        ],
      ),
    );
  }

  Widget _buildBadgesGrid() {
    final badges = _passportData['badges'] as List<dynamic>? ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 700;
        final count = isDesktop ? 5 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.9,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final b = badges[index] as Map<String, dynamic>;
            final isUnlocked = b['isUnlocked'] == true;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DSRadius.card),
                border: Border.all(color: isUnlocked ? DSColors.forestGreen.withValues(alpha: 0.3) : DSColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(b['icon'] as String, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  Text(
                    b['title'] as String,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: DSColors.forestGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    b['description'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 10, color: DSColors.textLight),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
