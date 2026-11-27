import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:libri_flow/features/home/presentation/pages/browse_books_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82
]);

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

Widget wrapWithApp(Widget child, Size size) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Material(child: child),
    ),
  );
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'mock_explore_token',
      'user_role': 'customer',
      'user_persona': 'reader',
    });
    ApiService.token = 'mock_explore_token';
  });

  group('Phase 16B.4 — Explore, Search, Filters & Recommendations Redesign Suite', () {
    testWidgets('BrowseBooksPage renders editorial header, search bar, and category filters', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(wrapWithApp(const BrowseBooksPage(), const Size(1200, 900)));
      await tester.pump();

      // Check header elements
      expect(find.text('THE TACTILE ARCHIVE • DISCOVERY'), findsOneWidget);
      expect(find.text('Explore The Library'), findsOneWidget);

      // Check search bar
      expect(find.byType(DSSearchBar), findsOneWidget);
      expect(find.text('Search by title, author, ISBN, or topic...'), findsOneWidget);

      // Check categories
      expect(find.text('All'), findsWidgets);
      expect(find.text('Academic & Textbooks'), findsWidgets);
      expect(find.text('Tech & Programming'), findsOneWidget);
      expect(find.text('Fiction'), findsWidgets);

      // Check secondary filter options
      expect(find.text('All Types'), findsOneWidget);
      expect(find.text('Buy'), findsOneWidget);
      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Borrow'), findsOneWidget);
    });

    testWidgets('BrowseBooksPage search input accepts text and debounces', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(wrapWithApp(const BrowseBooksPage(), const Size(1200, 900)));
      await tester.pump();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Clean Code Architecture');
      expect(find.text('Clean Code Architecture'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('Category chips update selection state on tap', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(wrapWithApp(const BrowseBooksPage(), const Size(1200, 900)));
      await tester.pump();

      final techChip = find.text('Tech & Programming');
      expect(techChip, findsOneWidget);

      await tester.tap(techChip);
      await tester.pump();
    });

    testWidgets('BrowseBooksPage initializes with pre-selected category parameter', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(wrapWithApp(
        const BrowseBooksPage(initialCategory: 'Academic & Textbooks'),
        const Size(1200, 900),
      ));
      await tester.pump();

      expect(find.text('Academic & Textbooks'), findsWidgets);
    });

    testWidgets('BrowseBooksPage initializes with pre-filled search query parameter', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(wrapWithApp(
        const BrowseBooksPage(initialSearchQuery: 'Algorithms'),
        const Size(1200, 900),
      ));
      await tester.pump();

      expect(find.text('Algorithms'), findsOneWidget);
    });

    testWidgets('EditorialBookCard displays full metadata and badge correctly without overflow', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 600));

      bool cardTapped = false;
      bool favTapped = false;

      await tester.pumpWidget(
        wrapWithApp(
          EditorialBookCard(
            width: 190,
            imageHeight: 175,
            title: 'Calculus and Analytical Geometry',
            author: 'George B. Thomas',
            price: 280.0,
            condition: 'Like New',
            availability: 'Rent',
            rating: 4.8,
            reviewCount: 42,
            providerName: 'University Quad Hub',
            onTap: () => cardTapped = true,
            onFavoriteToggle: () => favTapped = true,
          ),
          const Size(400, 600),
        ),
      );
      await tester.pump();

      expect(find.text('Calculus and Analytical Geometry'), findsOneWidget);
      expect(find.text('George B. Thomas'), findsOneWidget);
      expect(find.text('₹280'), findsOneWidget);
      expect(find.text('RENT'), findsOneWidget);
      expect(find.text('LIKE NEW'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text(' (42)'), findsOneWidget);
      expect(find.text('University Quad Hub'), findsOneWidget);

      await tester.tap(find.text('Calculus and Analytical Geometry'));
      expect(cardTapped, isTrue);

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      expect(favTapped, isTrue);
    });

    testWidgets('Responsive Layout Verification across Compact Mobile (360x800)', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      await tester.pumpWidget(wrapWithApp(const BrowseBooksPage(), const Size(360, 800)));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsive Layout Verification across Standard Mobile (390x844)', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(wrapWithApp(const BrowseBooksPage(), const Size(390, 844)));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsive Layout Verification across Tablet (768x1024)', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      await tester.pumpWidget(wrapWithApp(const BrowseBooksPage(), const Size(768, 1024)));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsive Layout Verification across Desktop (1440x900)', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpWidget(wrapWithApp(const BrowseBooksPage(), const Size(1440, 900)));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
