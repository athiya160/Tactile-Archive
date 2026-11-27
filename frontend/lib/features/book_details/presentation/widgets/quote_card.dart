import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

class QuoteCard extends StatelessWidget {
  final String quote;
  final String author;

  const QuoteCard({super.key, required this.quote, required this.author});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x4DC3C8C1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('"$quote"', style: IvoryTheme.quote),
          const SizedBox(height: 16),
          Text('— $author'.toUpperCase(), style: IvoryTheme.smallCapsLabel),
        ],
      ),
    );
  }
}
