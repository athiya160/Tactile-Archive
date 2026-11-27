import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeBenefitsBar extends StatelessWidget {
  const HomeBenefitsBar({super.key});

  static const _benefits = [
    {'icon': FontAwesomeIcons.bookOpen, 'label': 'Wide Collection', 'bg': Color(0xFFE8F5E9), 'iconColor': Color(0xFF2E7D32)},
    {'icon': FontAwesomeIcons.shieldHalved, 'label': 'Secure Payments', 'bg': Color(0xFFFFF8E1), 'iconColor': Color(0xFFF57F17)},
    {'icon': FontAwesomeIcons.truckFast, 'label': 'Fast Delivery', 'bg': Color(0xFFE3F2FD), 'iconColor': Color(0xFF1565C0)},
    {'icon': FontAwesomeIcons.rotateLeft, 'label': 'Easy Returns', 'bg': Color(0xFFF3E5F5), 'iconColor': Color(0xFF7B1FA2)},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFDFDFB),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 768;

              if (!isDesktop) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 3.2,
                  ),
                  itemCount: _benefits.length,
                  itemBuilder: (context, index) => _buildItem(_benefits[index]),
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _benefits.map((b) => Expanded(child: _buildItem(b))).toList(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: item['bg'] as Color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: FaIcon(
              item['icon'] as dynamic,
              color: item['iconColor'] as Color,
              size: 15,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            item['label'] as String,
            style: GoogleFonts.inter(
              color: const Color(0xFF061B0E),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
