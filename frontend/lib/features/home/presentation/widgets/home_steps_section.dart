import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeStepsSection extends StatelessWidget {
  const HomeStepsSection({super.key});

  static const _steps = [
    {
      'step': 1,
      'icon': FontAwesomeIcons.compass,
      'title': '1. Discover',
      'desc': 'Find books from our curated archive.'
    },
    {
      'step': 2,
      'icon': FontAwesomeIcons.comments,
      'title': '2. Connect',
      'desc': 'Chat with sellers or community members.'
    },
    {
      'step': 3,
      'icon': FontAwesomeIcons.rightLeft,
      'title': '3. Exchange',
      'desc': 'Buy, borrow, or rent with ease.'
    },
    {
      'step': 4,
      'icon': FontAwesomeIcons.bookOpen,
      'title': '4. Read & Return',
      'desc': 'Enjoy your book & return or resell.'
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
                          const Icon(Icons.flash_on_rounded, color: Color(0xFFC85A32), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'SIMPLE 4-STEP PROCESS',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: const Color(0xFFC85A32),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'How It Works',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: isDesktop ? 26 : 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0D3B2E),
                        ),
                      ),
                    ],
                  ),
                  if (!isDesktop)
                    Text(
                      'Swipe 👉',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF718096),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Four simple steps to borrow, buy, or share books in your neighborhood.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF718096),
                ),
                textAlign: isDesktop ? TextAlign.center : TextAlign.start,
              ),
              const SizedBox(height: 16),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < _steps.length; i++) ...[
                      Expanded(child: _buildDesktopStepCard(_steps[i])),
                      if (i < _steps.length - 1)
                        const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: Icon(Icons.chevron_right, color: Color(0xFFCBD5E0), size: 24),
                        ),
                    ]
                  ],
                )
              else
                // Amazon/Flipkart horizontal swipeable step cards
                SizedBox(
                  height: 132,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _steps.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final item = _steps[index];
                      return _buildMobileStepCard(item, index + 1);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileStepCard(Map<String, dynamic> item, int stepNumber) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D3B2E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'STEP 0$stepNumber',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
                ),
                child: Center(
                  child: FaIcon(
                    item['icon'] as dynamic,
                    color: const Color(0xFF0D3B2E),
                    size: 13,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['title'] as String,
                style: GoogleFonts.inter(
                  fontSize: 13,
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
                  fontSize: 11,
                  color: const Color(0xFF718096),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopStepCard(Map<String, dynamic> item) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFC8E6C9)),
          ),
          child: Center(
            child: FaIcon(
              item['icon'] as dynamic,
              color: const Color(0xFF0D3B2E),
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          item['title'] as String,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0D3B2E),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          item['desc'] as String,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF718096),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
