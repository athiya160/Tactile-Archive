import 'package:flutter/material.dart';

import 'package:libri_flow/core/design_system/design_system.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeWhyChooseUs extends StatelessWidget {
  const HomeWhyChooseUs({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DSColors.background,
      padding: const EdgeInsets.only(top: 32, bottom: 48),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Text(
                'Why Choose Us',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: DSColors.primary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Playfair Display',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Everything you need from a modern bookstore marketplace.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DSColors.textLight,
                  fontSize: 16.8,
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ResponsiveLayout(
                constrainWidth: false,
                mobile: _buildGrid(2, isMobile: true),
                tablet: _buildGrid(2, isMobile: false),
                desktop: _buildGrid(4, isMobile: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(int crossAxisCount, {required bool isMobile}) {
    final List<(dynamic, String, String)> reasons = const [
      (
        FontAwesomeIcons.tags,
        'Affordable',
        'Second-hand and rental prices that keep reading accessible.',
      ),
      (
        FontAwesomeIcons.leaf,
        'Sustainable',
        'Give books a second life and reduce waste.',
      ),
      (
        FontAwesomeIcons.userGraduate,
        'Student Friendly',
        'Textbook rentals and budget options for learners.',
      ),
      (
        FontAwesomeIcons.peopleGroup,
        'Community Driven',
        'Buy and sell directly with readers near you.',
      ),
    ];
    if (isMobile) {
      return Column(
        children: [
          for (var i = 0; i < reasons.length; i += 2) ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildReasonCard(
                      reasons[i].$1,
                      reasons[i].$2,
                      reasons[i].$3,
                    ),
                  ),
                  const SizedBox(width: 20),
                  if (i + 1 < reasons.length)
                    Expanded(
                      child: _buildReasonCard(
                        reasons[i + 1].$1,
                        reasons[i + 1].$2,
                        reasons[i + 1].$3,
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),
                ],
              ),
            ),
            if (i + 2 < reasons.length) const SizedBox(height: 20),
          ],
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < reasons.length; i++) ...[
            Expanded(
              child: _buildReasonCard(
                reasons[i].$1,
                reasons[i].$2,
                reasons[i].$3,
              ),
            ),
            if (i < reasons.length - 1) const SizedBox(width: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildReasonCard(dynamic icon, String title, String description) {
    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF0B3D2E).withValues(alpha: 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: FaIcon(
                    icon,
                    color: const Color(0xFFD4AF37),
                    size: 17.6,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Playfair Display',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF4A4A4A),
                  fontSize: 13.6,
                  fontFamily: 'Inter',
                  height: 1.55,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
