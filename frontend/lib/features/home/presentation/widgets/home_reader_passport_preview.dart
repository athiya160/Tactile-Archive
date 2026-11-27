import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/design_system/tokens/ds_colors.dart';

class HomeReaderPassportPreview extends StatelessWidget {
  const HomeReaderPassportPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DSColors.forestGreen,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;

              final leftSide = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: DSColors.warmGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: DSColors.warmGold),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(FontAwesomeIcons.passport, size: 14, color: DSColors.warmGold),
                        const SizedBox(width: 8),
                        Text(
                          '📖 MY ARCHIVE PASSPORT',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.8,
                            color: DSColors.warmGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your Personal Reading Identity & Progress Dashboard',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: isDesktop ? 32 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Track your verified reading tier, reading streaks, community badges, and exclusive access to rare book drops in one digital passport.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.88),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => context.push('/passport'),
                        icon: const FaIcon(FontAwesomeIcons.idCard, size: 15),
                        label: const Text('View Reader Passport'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DSColors.warmGold,
                          foregroundColor: DSColors.forestGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => context.push('/plans'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        child: const Text('Explore Tier Plans'),
                      ),
                    ],
                  ),
                ],
              );

              final rightSide = Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: DSColors.warmGold,
                          child: const FaIcon(FontAwesomeIcons.userCheck, color: DSColors.forestGreen, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ATHIYA • READER SINCE 2026',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.4,
                                color: DSColors.warmGold,
                              ),
                            ),
                            Text(
                              'Trusted Reader ⭐ 4.9',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),
                    _buildStatRow('📚 Books Read', '27 Volumes'),
                    const SizedBox(height: 10),
                    _buildStatRow('❤️ Favorites', '14 Saved'),
                    const SizedBox(height: 10),
                    _buildStatRow('🔥 Reading Streak', '12 Days'),
                    const SizedBox(height: 10),
                    _buildStatRow('🤝 Handoff Reputation', '18 Verified'),
                  ],
                ),
              );

              if (isDesktop) {
                return Row(
                  children: [
                    Expanded(flex: 6, child: leftSide),
                    const SizedBox(width: 44),
                    Expanded(flex: 5, child: rightSide),
                  ],
                );
              }

              return Column(
                children: [
                  leftSide,
                  const SizedBox(height: 28),
                  rightSide,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}
