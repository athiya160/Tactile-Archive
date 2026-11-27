import 'package:libri_flow/core/widgets/ivory_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return IvoryScaffold(
      showAppBar: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.lg,
          vertical: DSSpacing.xxl * 2,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'About The Tactile Archive',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: DSColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DSSpacing.xxl),
                Text(
                  'The Tactile Archive is a community-driven online book marketplace designed to make reading more accessible, affordable, and sustainable.\n\n'
                  'Our platform allows readers to buy, rent, borrow, exchange, and sell books with ease. Whether you are a student searching for academic textbooks, a reader looking for your next favorite novel, or someone wanting to give unused books a second life, The Tactile Archive provides a simple and convenient solution.\n\n'
                  'We believe that knowledge should be accessible to everyone. By encouraging the reuse and sharing of books, we help reduce costs for readers while promoting a more sustainable reading culture.\n\n'
                  'Our mission is to connect book lovers, students, and communities through a trusted platform where books can continue their journey from one reader to another.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    color: DSColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DSSpacing.xxl * 2),
                Text(
                  'Key Highlights',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: DSColors.primary,
                  ),
                ),
                const SizedBox(height: DSSpacing.xl),
                Wrap(
                  spacing: DSSpacing.md,
                  runSpacing: DSSpacing.md,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildHighlightChip('Buy affordable second-hand books'),
                    _buildHighlightChip(
                      'Rent textbooks and reference materials',
                    ),
                    _buildHighlightChip('Borrow books from the community'),
                    _buildHighlightChip('Exchange books with other readers'),
                    _buildHighlightChip('Sell books you no longer use'),
                    _buildHighlightChip(
                      'Support sustainable reading practices',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.md,
        vertical: DSSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: DSColors.primary,
        borderRadius: BorderRadius.circular(DSSpacing.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 16, color: DSColors.primary),
          const SizedBox(width: DSSpacing.xs),
          Text(
            text,
            style: const TextStyle(
              color: DSColors.textInverse,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
