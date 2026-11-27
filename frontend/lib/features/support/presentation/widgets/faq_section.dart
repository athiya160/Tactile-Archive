import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/faq.dart';
import 'faq_item.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class FaqSection extends StatelessWidget {
  final List<Faq> faqs;

  const FaqSection({super.key, required this.faqs});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DSColors.surface.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.lg,
        vertical: DSSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequently Asked Questions',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: DSColors.textDark),
          ),
          const SizedBox(height: DSSpacing.lg),
          ...faqs.map((faq) => FaqItem(faq: faq)),
          const SizedBox(height: DSSpacing.sm),
          TextButton(
            onPressed: () => context.push('/faqs'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'View all FAQs',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: DSColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
