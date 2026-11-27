import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class HomeFeatureCardsRow extends StatelessWidget {
  const HomeFeatureCardsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFDFBF7),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;

            if (isDesktop) {
              return Row(
                children: [
                  Expanded(
                    child: _FeatureCard(
                      icon: FontAwesomeIcons.brain,
                      iconBg: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF2E7D32),
                      badge: '🧠 AI RECOMMENDATIONS',
                      title: 'Find Your Next Book',
                      description: 'Tell us your mood, reading goals, or favorite themes to discover your match.',
                      buttonText: 'Discover Match →',
                      onTap: () => context.push('/mood-match'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _FeatureCard(
                      icon: FontAwesomeIcons.graduationCap,
                      iconBg: const Color(0xFFFFF8E1),
                      iconColor: const Color(0xFFF57F17),
                      badge: '🎓 SEMESTER PLANNER',
                      title: 'Plan Your Semester',
                      description: 'Organize your subjects, exams, required readings, and study tasks effortlessly.',
                      buttonText: 'Plan My Semester →',
                      onTap: () => context.push('/semester-planner'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _FeatureCard(
                      icon: FontAwesomeIcons.camera,
                      iconBg: const Color(0xFFE3F2FD),
                      iconColor: const Color(0xFF1565C0),
                      badge: '📷 SHELF SCANNER',
                      title: 'Scan Your Shelf',
                      description: 'Snap a photo of your bookshelf to identify books and find catalog matches instantly.',
                      buttonText: 'Scan Shelf →',
                      onTap: () => context.push('/shelf-scanner'),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                _FeatureCard(
                  icon: FontAwesomeIcons.brain,
                  iconBg: const Color(0xFFE8F5E9),
                  iconColor: const Color(0xFF2E7D32),
                  badge: '🧠 AI RECOMMENDATIONS',
                  title: 'Find Your Next Book',
                  description: 'Tell us your mood, reading goals, or favorite themes to discover your match.',
                  buttonText: 'Discover Match →',
                  onTap: () => context.push('/mood-match'),
                ),
                const SizedBox(height: 16),
                _FeatureCard(
                  icon: FontAwesomeIcons.graduationCap,
                  iconBg: const Color(0xFFFFF8E1),
                  iconColor: const Color(0xFFF57F17),
                  badge: '🎓 SEMESTER PLANNER',
                  title: 'Plan Your Semester',
                  description: 'Organize your subjects, exams, required readings, and study tasks effortlessly.',
                  buttonText: 'Plan My Semester →',
                  onTap: () => context.push('/semester-planner'),
                ),
                const SizedBox(height: 16),
                _FeatureCard(
                  icon: FontAwesomeIcons.camera,
                  iconBg: const Color(0xFFE3F2FD),
                  iconColor: const Color(0xFF1565C0),
                  badge: '📷 SHELF SCANNER',
                  title: 'Scan Your Shelf',
                  description: 'Snap a photo of your bookshelf to identify books and find catalog matches instantly.',
                  buttonText: 'Scan Shelf →',
                  onTap: () => context.push('/shelf-scanner'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final dynamic icon;
  final Color iconBg;
  final Color iconColor;
  final String badge;
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.badge,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onTap,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered ? widget.iconColor.withValues(alpha: 0.4) : const Color(0xFFEDF2F7),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.iconColor.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: _isHovered ? 18 : 8,
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: FaIcon(
                        widget.icon as dynamic,
                        color: widget.iconColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.badge,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: widget.iconColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.title,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0D3B2E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF718096),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    widget.buttonText,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: widget.iconColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
