import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/design_system/tokens/ds_colors.dart';

class HomeExchangeHubsPreview extends StatelessWidget {
  const HomeExchangeHubsPreview({super.key});

  static const _hubs = [
    {
      'title': 'Tactile Hub — Central Library',
      'address': 'Westgate St, Central Plaza, Hub Counter #2',
      'distance': '0.8 km away',
      'activeExchanges': '🟢 Open • 24/7 Smart Lockers',
    },
    {
      'title': 'Tactile Hub — Green Valley',
      'address': '74 Valley Promenade, Commons Room 104',
      'distance': '1.2 km away',
      'activeExchanges': '🟢 Open • 🛡 Verified Counter',
    },
    {
      'title': 'Tactile Hub — Tech Park Annex',
      'address': '404 Silicon Way, Innovation Kiosk #3',
      'distance': '1.8 km away',
      'activeExchanges': '🟢 Open • 📹 CCTV Monitored',
    },
    {
      'title': 'Tactile Hub — University Quad',
      'address': 'Academic Circle, Student Union Ground Floor',
      'distance': '2.1 km away',
      'activeExchanges': '🟢 Open • 🎓 Student Station',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    return Container(
      color: DSColors.warmCreamLight,
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 48 : 22,
        horizontal: isDesktop ? 20 : 16,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '📍 NEARBY EXCHANGE HUBS',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                                color: DSColors.terracotta,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Local Book Swap & Drop-off Points',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: isDesktop ? 28 : 20,
                            fontWeight: FontWeight.bold,
                            color: DSColors.forestGreen,
                          ),
                        ),
                        if (isDesktop) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Meet local readers at verified community hubs to handoff or collect physical books safely.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: DSColors.textLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push('/exchange-map'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: DSColors.forestGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(FontAwesomeIcons.mapLocationDot, size: 12, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            isDesktop ? 'Interactive Map' : 'Map View',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (isDesktop)
                Row(
                  children: _hubs.map((hub) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _buildDesktopHubCard(context, hub),
                    ),
                  )).toList(),
                )
              else
                // Amazon/Flipkart horizontal swipeable hubs rail
                SizedBox(
                  height: 145,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _hubs.length + 1,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      if (index == _hubs.length) {
                        return _buildMapCtaCard(context);
                      }
                      return _buildMobileHubCard(context, _hubs[index]);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileHubCard(BuildContext context, Map<String, String> hub) {
    return InkWell(
      onTap: () => context.push('/exchange-map'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DSColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: DSColors.softMint,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const FaIcon(FontAwesomeIcons.locationDot, color: DSColors.forestGreen, size: 13),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hub['title']!,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: DSColors.forestGreen,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              hub['address']!,
              style: GoogleFonts.inter(fontSize: 11, color: DSColors.textDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    hub['distance']!,
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFB7791F)),
                  ),
                ),
                Text(
                  hub['activeExchanges']!,
                  style: GoogleFonts.inter(fontSize: 9.5, color: DSColors.textLight),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCtaCard(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/exchange-map'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC8E6C9)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(FontAwesomeIcons.mapLocationDot, color: Color(0xFF0D3B2E), size: 24),
            const SizedBox(height: 8),
            Text(
              'Explore 15+ Hubs',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0D3B2E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              'View on Map →',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopHubCard(BuildContext context, Map<String, String> hub) {
    return InkWell(
      onTap: () => context.push('/exchange-map'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DSColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DSColors.softMint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const FaIcon(FontAwesomeIcons.locationDot, color: DSColors.forestGreen, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hub['title']!,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DSColors.forestGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              hub['address']!,
              style: GoogleFonts.inter(fontSize: 12, color: DSColors.textDark),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hub['distance']!,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DSColors.warmGold),
                ),
                Text(
                  hub['activeExchanges']!,
                  style: GoogleFonts.inter(fontSize: 11, color: DSColors.textLight),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
