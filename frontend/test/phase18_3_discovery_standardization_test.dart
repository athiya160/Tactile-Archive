import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/core/design_system/tokens/ds_colors.dart';
import 'package:libri_flow/core/design_system/tokens/ds_radius.dart';
import 'package:libri_flow/core/design_system/components/ds_buttons.dart';
import 'package:libri_flow/features/home/presentation/widgets/browse_book_card.dart';
import 'package:libri_flow/features/home/domain/entities/book.dart';

void main() {
  group('Phase 18.3 — Discovery & Navigation Design System Tokens Verification', () {
    test('DSColors canonical tokens match Phase 18 design specification', () {
      expect(DSColors.deepForestGreen, const Color(0xFF183D32));
      expect(DSColors.secondaryGreen, const Color(0xFF285C49));
      expect(DSColors.warmIvory, const Color(0xFFF8F5EE));
      expect(DSColors.paperWhite, const Color(0xFFFFFDF8));
      expect(DSColors.charcoal, const Color(0xFF252923));
      expect(DSColors.softBorder, const Color(0xFFE7E1D6));
      expect(DSColors.accentTerracotta, const Color(0xFFC47C62));
    });

    test('DSRadius canonical tokens match editorial design standards', () {
      expect(DSRadius.xs, 4.0);
      expect(DSRadius.sm, 8.0);
      expect(DSRadius.md, 12.0);
      expect(DSRadius.card, 20.0);
      expect(DSRadius.xl, 28.0);
      expect(DSRadius.pill, 9999.0);
    });

    test('DSButton default height complies with 48px accessible touch target', () {
      const button = DSButton(text: 'Explore Archive');
      expect(button.height, 48.0);
    });

    testWidgets('BrowseBookCard renders with standardized brand tokens', (WidgetTester tester) async {
      final book = Book(
        id: '1',
        title: 'Designing Data-Intensive Applications',
        author: 'Martin Kleppmann',
        coverUrl: 'https://example.com/cover.jpg',
        price: 850.0,
        originalPrice: 1200.0,
        rating: 4.9,
        category: 'Technology',
        categories: const ['Technology', 'Computing'],
        listingType: ListingType.forSale,
        canBuy: true,
        canRent: true,
        condition: 'Like New',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 250,
                child: BrowseBookCard(book: book),
              ),
            ),
          ),
        ),
      );

      // Verify book title and author render cleanly
      expect(find.text('Designing Data-Intensive Applications'), findsOneWidget);
      expect(find.text('by Martin Kleppmann'), findsOneWidget);
    });
  });
}
