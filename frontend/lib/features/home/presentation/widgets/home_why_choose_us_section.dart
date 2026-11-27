import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeWhyChooseUsSection extends StatelessWidget {
  const HomeWhyChooseUsSection({super.key});

  static const _features = [
    {
      'icon': FontAwesomeIcons.users,
      'title': 'Community Driven',
      'desc': 'Built by readers, for readers'
    },
    {
      'icon': FontAwesomeIcons.shieldHalved,
      'title': 'Safe & Secure',
      'desc': 'Verified users & safe transactions'
    },
    {
      'icon': FontAwesomeIcons.tag,
      'title': 'Affordable',
      'desc': 'Best prices with community trust'
    },
    {
      'icon': FontAwesomeIcons.leaf,
      'title': 'Sustainable',
      'desc': 'Promoting reuse & sustainability'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 40 : 24,
        horizontal: isDesktop ? 24 : 16,
      ),
      color: const Color(0xFFFDFBF7),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: isDesktop ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: isDesktop ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: isDesktop ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user_rounded, color: Color(0xFF2E7D32), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'TACTILE ASSURED',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Why Choose The Tactile Archive?',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: isDesktop ? 26 : 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0D3B2E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < _features.length; i++) ...[
                      Expanded(child: _buildDesktopFeatureItem(_features[i])),
                      if (i < _features.length - 1) const SizedBox(width: 16),
                    ]
                  ],
                )
              else
                // Amazon/Flipkart style 2x2 trust badge grid
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildMobileTrustCard(_features[0])),
                        const SizedBox(width: 10),
                        Expanded(child: _buildMobileTrustCard(_features[1])),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildMobileTrustCard(_features[2])),
                        const SizedBox(width: 10),
                        Expanded(child: _buildMobileTrustCard(_features[3])),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileTrustCard(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
            ),
            child: Center(
              child: FaIcon(
                item['icon'] as dynamic,
                color: const Color(0xFF0D3B2E),
                size: 15,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item['title'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D3B2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item['desc'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: const Color(0xFF718096),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFeatureItem(Map<String, dynamic> item) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: FaIcon(
              item['icon'] as dynamic,
              color: const Color(0xFF0D3B2E),
              size: 18,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          item['title'] as String,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0D3B2E),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          item['desc'] as String,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF718096),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
