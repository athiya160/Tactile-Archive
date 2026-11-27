import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

void main() {
  group('Checkpoint A — Design Tokens Verification', () {
    test('DSColors matches luxury editorial palette exactly', () {
      expect(DSColors.deepForestGreen, const Color(0xFF183D32));
      expect(DSColors.secondaryGreen, const Color(0xFF285C49));
      expect(DSColors.warmIvory, const Color(0xFFF8F5EE));
      expect(DSColors.paperWhite, const Color(0xFFFFFDF8));
      expect(DSColors.mutedTerracotta, const Color(0xFFC47C62));
      expect(DSColors.charcoal, const Color(0xFF252923));
      expect(DSColors.softBorder, const Color(0xFFE7E1D6));

      // Backward-compatible aliases
      expect(DSColors.primary, const Color(0xFF183D32));
      expect(DSColors.background, const Color(0xFFF8F5EE));
      expect(DSColors.surface, const Color(0xFFFFFDF8));
      expect(DSColors.accent, const Color(0xFFC47C62));
      expect(DSColors.textDark, const Color(0xFF252923));
      expect(DSColors.border, const Color(0xFFE7E1D6));
    });

    test('DSRadius includes 20px card radius for editorial aesthetic', () {
      expect(DSRadius.card, 20.0);
      expect(DSRadius.lg, 20.0);
    });

    test('DSShadows has layered natural depth shadows', () {
      expect(DSShadows.sm.isNotEmpty, isTrue);
      expect(DSShadows.md.length, 2);
      expect(DSShadows.bookCard.isNotEmpty, isTrue);
      expect(DSShadows.bookCardHover.isNotEmpty, isTrue);
    });
  });

  group('Checkpoint B — Reusable Components Widget Tests', () {
    Widget buildTestableWidget(Widget child) {
      return MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: DSColors.background,
        ),
        home: Scaffold(
          body: Center(child: child),
        ),
      );
    }

    testWidgets('DSButton renders variants and responds to taps', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        buildTestableWidget(
          DSButton.primary(
            text: 'Explore Books',
            onPressed: () => pressed = true,
          ),
        ),
      );

      expect(find.text('Explore Books'), findsOneWidget);
      await tester.tap(find.text('Explore Books'));
      expect(pressed, isTrue);

      // Test loading state
      await tester.pumpWidget(
        buildTestableWidget(
          const DSButton(
            text: 'Processing',
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('DSTextField and DSSearchBar render and take input', (tester) async {
      final controller = TextEditingController();
      bool scanTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          Column(
            children: [
              DSTextField(
                labelText: 'Email Address',
                hintText: 'user@example.com',
                controller: controller,
              ),
              DSSearchBar(
                hintText: 'Search the archive...',
                onScanTap: () => scanTapped = true,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('user@example.com'), findsOneWidget);
      expect(find.text('Search the archive...'), findsOneWidget);
      expect(find.text('SCAN'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'reader@archive.org');
      expect(controller.text, 'reader@archive.org');

      await tester.tap(find.text('SCAN'));
      expect(scanTapped, isTrue);
    });

    testWidgets('EditorialBookCard renders book metadata and handles taps', (tester) async {
      bool cardTapped = false;
      bool favoriteToggled = false;

      await tester.pumpWidget(
        buildTestableWidget(
          EditorialBookCard(
            title: 'Window into Dawn',
            author: 'Sarah Penrose',
            price: 180.0,
            condition: 'Like New',
            availability: 'Rent',
            rating: 4.9,
            reviewCount: 86,
            providerName: 'Meridian Books',
            onTap: () => cardTapped = true,
            onFavoriteToggle: () => favoriteToggled = true,
          ),
        ),
      );

      expect(find.text('Window into Dawn'), findsOneWidget);
      expect(find.text('Sarah Penrose'), findsOneWidget);
      expect(find.text('₹180'), findsOneWidget);
      expect(find.text('LIKE NEW'), findsOneWidget);
      expect(find.text('RENT'), findsOneWidget);
      expect(find.text('4.9'), findsOneWidget);
      expect(find.text(' (86)'), findsOneWidget);
      expect(find.text('Meridian Books'), findsOneWidget);

      await tester.tap(find.text('Window into Dawn'));
      expect(cardTapped, isTrue);

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      expect(favoriteToggled, isTrue);
    });

    testWidgets('SectionHeading renders eyebrow, title, and action', (tester) async {
      bool actionClicked = false;

      await tester.pumpWidget(
        buildTestableWidget(
          SectionHeading(
            eyebrow: 'Curated Collection',
            title: 'Rare First Editions',
            subtitle: 'Signed archival copies from verified collectors',
            actionText: 'View All',
            onAction: () => actionClicked = true,
          ),
        ),
      );

      expect(find.text('CURATED COLLECTION'), findsOneWidget);
      expect(find.text('Rare First Editions'), findsOneWidget);
      expect(find.text('Signed archival copies from verified collectors'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);

      await tester.tap(find.text('View All'));
      expect(actionClicked, isTrue);
    });

    testWidgets('DSChip and DSBadge render with correct states', (tester) async {
      bool selected = false;

      await tester.pumpWidget(
        buildTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return Row(
                children: [
                  DSChip(
                    label: 'Textbooks',
                    isSelected: selected,
                    count: 14,
                    onSelected: (val) => setState(() => selected = val),
                  ),
                  const DSBadge(
                    text: 'Verified Provider',
                    variant: DSBadgeVariant.success,
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('Textbooks'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('VERIFIED PROVIDER'), findsOneWidget);

      await tester.tap(find.text('Textbooks'));
      await tester.pumpAndSettle();
      expect(selected, isTrue);
    });

    testWidgets('DSEmptyState renders and responds to action button', (tester) async {
      bool emptyActionPressed = false;

      await tester.pumpWidget(
        buildTestableWidget(
          DSEmptyState(
            icon: Icons.menu_book,
            title: 'No Books Saved',
            description: 'Bookmark books from the catalog to find them later.',
            actionLabel: 'Browse Archive',
            onAction: () => emptyActionPressed = true,
          ),
        ),
      );

      expect(find.text('No Books Saved'), findsOneWidget);
      expect(find.text('Browse Archive'), findsOneWidget);

      await tester.tap(find.text('Browse Archive'));
      expect(emptyActionPressed, isTrue);
    });

    testWidgets('DSErrorState renders error message and triggers retry', (tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        buildTestableWidget(
          DSErrorState(
            title: 'Network Timeout',
            message: 'Failed to connect to backend on port 8000.',
            onRetry: () => retryPressed = true,
          ),
        ),
      );

      expect(find.text('Network Timeout'), findsOneWidget);
      expect(find.text('Failed to connect to backend on port 8000.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retryPressed, isTrue);
    });

    testWidgets('DSSkeleton and DSSkeletonBookCard render without error', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Column(
            children: [
              DSSkeleton(width: 120, height: 20),
              DSSkeletonBookCard(width: 190),
            ],
          ),
        ),
      );

      expect(find.byType(DSSkeleton), findsWidgets);
      expect(find.byType(DSSkeletonBookCard), findsOneWidget);
    });

    testWidgets('DSDialog displays content and triggers primary action', (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    DSDialog.show(
                      context,
                      title: 'Confirm Rental',
                      content: 'Rent "Window into Dawn" for 14 days at ₹180?',
                      primaryActionLabel: 'Confirm',
                      onPrimaryAction: () {
                        confirmed = true;
                        Navigator.of(context).pop();
                      },
                      secondaryActionLabel: 'Cancel',
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Rental'), findsOneWidget);
      expect(find.text('Rent "Window into Dawn" for 14 days at ₹180?'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);
    });

    testWidgets('DSResponsiveContainer applies layout constraints', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DSResponsiveContainer(
              maxWidth: 800,
              child: const Text('Responsive Content'),
            ),
          ),
        ),
      );

      expect(find.text('Responsive Content'), findsOneWidget);
      expect(find.byType(DSResponsiveContainer), findsOneWidget);
    });
  });
}
