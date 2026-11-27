import 'package:flutter/material.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeHowItWorks extends StatelessWidget {
  const HomeHowItWorks({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 48, bottom: 48), // 3rem 0
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Text(
                'How It Works',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: DSColors.primary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Playfair Display',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Three simple steps to your next great read.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DSColors.textLight,
                  fontSize: 16,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 48), // margin before steps
              ResponsiveLayout(
                constrainWidth: false,
                mobile: _buildSteps(isMobile: true),
                tablet: _buildSteps(isMobile: false),
                desktop: _buildSteps(isMobile: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSteps({required bool isMobile}) {
    final steps = [
      (
        '1',
        FontAwesomeIcons.magnifyingGlass,
        'Browse Books',
        'Search thousands of titles across every genre and format.',
      ),
      (
        '2',
        FontAwesomeIcons.handHolding,
        'Buy / Rent / Borrow',
        'Choose the option that fits your budget and reading goals.',
      ),
      (
        '3',
        FontAwesomeIcons.bookOpenReader,
        'Read & Enjoy',
        'Receive your book and start reading — it is that simple.',
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            _buildStepCard(steps[i].$1, steps[i].$2, steps[i].$3, steps[i].$4),
            if (i < steps.length - 1) const SizedBox(height: 24), // 1.5rem gap
          ],
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Expanded(
              child: _buildStepCard(
                steps[i].$1,
                steps[i].$2,
                steps[i].$3,
                steps[i].$4,
              ),
            ),
            if (i < steps.length - 1) const SizedBox(width: 24), // 1.5rem gap
          ],
        ],
      ),
    );
  }

  Widget _buildStepCard(
    String stepNumber,
    dynamic icon,
    String title,
    String description,
  ) {
    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(
            vertical: 32,
            horizontal: 24,
          ), // 2rem 1.5rem
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16), // radius-lg
            border: Border.all(
              color: const Color(0xFF0B3D2E).withValues(alpha: 0.06),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000), // shadow-sm
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -16, // absolute top: 1rem (relative to parent padding)
                right: -8, // absolute right: 1rem
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      stepNumber,
                      style: const TextStyle(
                        color: Color(0xFF0B3D2E),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.8, // 0.8rem
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B3D2E).withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: FaIcon(
                        icon,
                        color: const Color(0xFF0B3D2E),
                        size: 21.6, // 1.35rem
                      ),
                    ),
                  ),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 17.6, // 1.1rem
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 8), // 0.5rem margin-bottom on title
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF4A4A4A), // text-light
                      fontSize: 14.4, // 0.9rem
                      fontFamily: 'Inter',
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
