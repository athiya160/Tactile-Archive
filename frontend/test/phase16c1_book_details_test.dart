import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:libri_flow/features/home/domain/entities/book.dart';
import 'package:libri_flow/features/home/data/models/book_model.dart';
import 'package:libri_flow/features/book_details/presentation/widgets/book_info_section.dart';
import 'package:libri_flow/features/book_details/presentation/widgets/book_action_card.dart';
import 'package:libri_flow/features/book_details/presentation/pages/book_details_page.dart';
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
    return Stream<List<int>>.value(_kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
    SharedPreferences.setMockInitialValues({'auth_token': 'mock_details_token'});
    ApiService.token = 'mock_details_token';
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  final testBook = Book(
    id: '42',
    title: 'The Codex of Rare Folios',
    author: 'Archivist Thorne',
    coverUrl: 'https://images.unsplash.com/photo-1544947950-fa07a98d237f',
    categories: ['Academic & Textbooks', 'History'],
    category: 'Academic & Textbooks',
    price: 450.0,
    originalPrice: 600.0,
    discountPercentage: 25.0,
    listingType: ListingType.forRent,
    rating: 4.8,
    totalReviews: 19,
    description: 'An authoritative catalog of illuminated medieval manuscripts.',
    isbn: '978-0198534531',
    publisher: 'Clarendon Archives',
    language: 'English',
    pages: '512 pages',
    condition: 'Fine Pristine',
    stock: 4,
    provider: {
      'id': 101,
      'name': 'Prof. Eleanor Vance',
      'is_verified': true,
      'campus': 'Oxford Archives',
      'rating': null,
    },
    providerName: 'Prof. Eleanor Vance',
    providerCampus: 'Oxford Archives',
    providerVerified: true,
    providerRating: null,
    isAvailable: true,
    availabilityStatus: 'in_stock',
    canBuy: true,
    canRent: true,
    canBorrow: true,
    rentalOptions: {
      'daily_rate': 6.75,
      'fee_7d': 45.0,
      'fee_14d': 67.5,
      'fee_30d': 112.5,
      'deposit': 225.0,
    },
  );

  final outOfStockBook = testBook.copyWith(
    id: '43',
    stock: 0,
    isAvailable: false,
    availabilityStatus: 'out_of_stock',
    canBuy: false,
    canRent: false,
  );

  group('Phase 16C.1 — Book Model & Entity Unit Tests', () {
    test('BookModel.fromJson parses full provider and availability payload', () {
      final json = {
        'id': '101',
        'title': 'Illuminated Manuscripts',
        'author': 'Brother Gabriel',
        'price': 250.0,
        'rating': 4.7,
        'stock': 2,
        'provider': {
          'id': 5,
          'name': 'Monastery Scriptorium',
          'is_verified': true,
          'campus': 'St. Jude Priory',
          'rating': 4.9,
        },
        'is_available': true,
        'availability_status': 'in_stock',
        'can_buy': true,
        'can_rent': true,
        'can_borrow': false,
        'rental_options': {
          'daily_rate': 4.0,
          'fee_7d': 25.0,
          'fee_14d': 40.0,
          'fee_30d': 70.0,
          'deposit': 125.0,
        },
      };

      final model = BookModel.fromJson(json);
      expect(model.id, equals('101'));
      expect(model.title, equals('Illuminated Manuscripts'));
      expect(model.providerName, equals('Monastery Scriptorium'));
      expect(model.providerCampus, equals('St. Jude Priory'));
      expect(model.providerVerified, isTrue);
      expect(model.providerRating, equals(4.9));
      expect(model.isAvailable, isTrue);
      expect(model.canBuy, isTrue);
      expect(model.canBorrow, isFalse);
      expect(model.rentalOptions?['deposit'], equals(125.0));
    });

    test('BookModel.toJson serializes provider and availability fields accurately', () {
      final json = {
        'id': '102',
        'title': 'Rare Folios',
        'author': 'Scribe Anthony',
        'price': 100.0,
        'rating': 4.5,
        'stock': 1,
        'provider_name': 'Rare Books Vault',
        'provider_campus': 'Trinity Library',
        'provider_verified': true,
        'is_available': true,
        'availability_status': 'in_stock',
        'can_buy': true,
        'can_rent': false,
        'can_borrow': true,
      };

      final model = BookModel.fromJson(json);
      final serialized = model.toJson();
      expect(serialized['provider_name'], equals('Rare Books Vault'));
      expect(serialized['provider_campus'], equals('Trinity Library'));
      expect(serialized['provider_verified'], isTrue);
      expect(serialized['is_available'], isTrue);
      expect(serialized['can_buy'], isTrue);
      expect(serialized['can_rent'], isFalse);
    });

    test('Book copyWith modifies availability and provider state without mutation', () {
      final updated = testBook.copyWith(
        stock: 0,
        isAvailable: false,
        availabilityStatus: 'out_of_stock',
      );

      expect(testBook.stock, equals(4));
      expect(testBook.isAvailable, isTrue);
      expect(updated.stock, equals(0));
      expect(updated.isAvailable, isFalse);
      expect(updated.title, equals(testBook.title));
      expect(updated.providerName, equals(testBook.providerName));
    });
  });

  group('Phase 16C.1 — BookInfoSection Widget Tests', () {
    testWidgets('Renders real book metadata and stock badge without dummy fallbacks', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BookInfoSectionV2(book: testBook),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('The Codex of Rare Folios'), findsOneWidget);
      expect(find.textContaining('Archivist Thorne'), findsOneWidget);
      expect(find.text('IN STOCK (4)'), findsOneWidget);
      expect(find.text('978-0198534531'), findsOneWidget);
      expect(find.text('Clarendon Archives'), findsOneWidget);
      expect(find.text('512 pages'), findsOneWidget);
    });

    testWidgets('Renders dedicated authentic Provider Card with verified badge and campus', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BookInfoSectionV2(book: testBook),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prof. Eleanor Vance'), findsOneWidget);
      expect(find.text('📍 Oxford Archives'), findsOneWidget);
      expect(find.text('New Seller'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsWidgets);
    });

    testWidgets('Renders OUT OF STOCK badge when stock is 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BookInfoSectionV2(book: outOfStockBook),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OUT OF STOCK'), findsOneWidget);
    });
  });

  group('Phase 16C.1 — BookActionCard Widget Tests', () {
    testWidgets('Renders transaction tabs and switches between Rent, Borrow, Buy', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BookActionCard(
                book: testBook,
                onAddToCart: () {},
                onBuyNow: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Borrow'), findsOneWidget);
      expect(find.text('Buy'), findsOneWidget);

      // Tap Buy tab
      await tester.tap(find.text('Buy'));
      await tester.pumpAndSettle();

      expect(find.text('Purchase Price'), findsOneWidget);
      expect(find.text('₹450'), findsOneWidget);
      expect(find.text('Buy & Own Now'), findsOneWidget);
      expect(find.text('Add to Cart'), findsOneWidget);
    });

    testWidgets('Displays out of stock banner and disables CTA when book is unavailable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BookActionCard(
                book: outOfStockBook,
                onAddToCart: () {},
                onBuyNow: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Currently Out of Stock'), findsOneWidget);
      expect(find.text('Currently Unavailable'), findsOneWidget);
    });

    testWidgets('Computes dynamic rental rate and deposit from rental options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BookActionCard(
                book: testBook,
                onAddToCart: () {},
                onBuyNow: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check default 14-day rental fee (₹67) and deposit (₹225)
      expect(find.textContaining('Refundable Security Deposit: ₹225'), findsOneWidget);
      expect(find.textContaining('for 14 days'), findsOneWidget);
    });
  });

  group('Phase 16C.1 — Multi-Viewport Responsive Layout Tests', () {
    final viewports = <String, Size>{
      'Compact Mobile (360x800)': const Size(360, 800),
      'Standard Mobile (390x844)': const Size(390, 844),
      'Tablet Portrait (768x1024)': const Size(768, 1024),
      'Desktop (1440x900)': const Size(1440, 900),
    };

    for (final entry in viewports.entries) {
      testWidgets('BookDetailsContent layout renders without overflow on ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: BookDetailsContent(
                book: testBook,
                isFavorite: false,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.text('The Codex of Rare Folios'), findsOneWidget);
      });
    }
  });
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}
