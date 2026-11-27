import 'package:flutter/material.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class QuoteSection extends StatelessWidget {
  final String quote;
  final String author;

  const QuoteSection({super.key, required this.quote, required this.author});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 64, bottom: 48), // mt-16 mb-12
      padding: const EdgeInsets.symmetric(vertical: 40), // py-10
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: DSColors.borderLight)),
      ),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              '"$quote"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20, // text-xl
                height: 1.6,
                color: DSColors.primary,
              ),
            ),
          ),
          const SizedBox(height: DSSpacing.sm),
          Text(
            author.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: DSColors.textLight,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
