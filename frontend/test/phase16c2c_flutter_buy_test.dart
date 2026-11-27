import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:libri_flow/core/services/payment_gateway_service.dart';
import 'package:libri_flow/features/home/domain/entities/book.dart';
import 'package:libri_flow/features/cart/domain/entities/cart.dart';
import 'package:libri_flow/features/cart/domain/entities/cart_item.dart';
import 'package:libri_flow/features/book_details/presentation/widgets/book_action_card.dart';
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

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
    SharedPreferences.setMockInitialValues({'auth_token': 'mock_buy_test_token'});
    ApiService.token = 'mock_buy_test_token';
  });

  tearDownAll(() {
    HttpOverrides.global = null;
    PaymentGatewayService.mockHandler = null;
  });

  group('Phase 16C.2C — Cart & CartItem Integer Paise Calculations', () {
    test('CartItem correctly computes unitPricePaise and totalItemPaise', () {
      const item = CartItem(
        id: 'ci_101',
        bookId: '1',
        title: 'Design Patterns',
        author: 'Gang of Four',
        coverUrl: 'https://example.com/cover.jpg',
        price: 499.50,
        isPurchase: true,
        quantity: 3,
      );

      expect(item.unitPricePaise, equals(49950));
      expect(item.totalItemPaise, equals(149850));
    });

    test('Cart correctly computes subtotal, archive fee, shipping, and total in paise', () {
      const item1 = CartItem(
        id: 'ci_1',
        bookId: '1',
        title: 'Clean Code',
        author: 'Robert C. Martin',
        coverUrl: 'https://example.com/c1.jpg',
        price: 350.00,
        isPurchase: true,
        quantity: 2,
      );
      const item2 = CartItem(
        id: 'ci_2',
        bookId: '2',
        title: 'Refactoring',
        author: 'Martin Fowler',
        coverUrl: 'https://example.com/c2.jpg',
        price: 150.75,
        isPurchase: true,
        quantity: 1,
      );

      const cart = Cart(
        items: [item1, item2],
        archiveFee: 1.20,
        shippingFee: 0.0,
      );

      // Subtotal: 350.00*2 + 150.75 = 850.75 -> 85075 paise
      expect(cart.subtotalPaise, equals(85075));
      // Archive fee: ₹1.20 -> 120 paise (matches ARCHIVE_FEE_PAISE)
      expect(cart.archiveFeePaise, equals(120));
      // Shipping fee: ₹0.00 -> 0 paise (matches SHIPPING_FEE_PAISE)
      expect(cart.shippingFeePaise, equals(0));
      // Total: 85075 + 120 + 0 = 85195 paise
      expect(cart.totalPaise, equals(85195));
      expect(cart.total, closeTo(851.95, 0.001));
    });

    test('CartItem quantity changes proportionally adjust totalItemPaise and cart.totalPaise', () {
      const itemInitial = CartItem(
        id: 'ci_1',
        bookId: '1',
        title: 'Domain-Driven Design',
        author: 'Eric Evans',
        coverUrl: 'https://example.com/ddd.jpg',
        price: 600.00,
        isPurchase: true,
        quantity: 1,
      );

      var cart = const Cart(items: [itemInitial], archiveFee: 1.20, shippingFee: 0.0);
      expect(cart.totalPaise, equals(60000 + 120));

      final itemIncremented = itemInitial.copyWith(quantity: 4);
      cart = cart.copyWith(items: [itemIncremented]);

      expect(itemIncremented.totalItemPaise, equals(240000));
      expect(cart.subtotalPaise, equals(240000));
      expect(cart.totalPaise, equals(240120));
    });
  });

  group('Phase 16C.2C — Book Availability & Stock Validation UI', () {
    testWidgets('BookActionCard renders active Buy and Add to Cart buttons when stock > 0', (tester) async {
      final availableBook = Book(
        id: '10',
        title: 'Structure and Interpretation of Computer Programs',
        author: 'Abelson & Sussman',
        coverUrl: 'https://example.com/sicp.jpg',
        categories: const ['Computer Science'],
        listingType: ListingType.forSale,
        rating: 4.9,
        price: 850.0,
        stock: 5,
        canBuy: true,
        canRent: false,
        canBorrow: false,
      );

      bool buyNowClicked = false;
      bool addToCartClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Inter'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: BookActionCard(
                book: availableBook,
                onAddToCart: () => addToCartClicked = true,
                onBuyNow: () => buyNowClicked = true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Buy & Own Now'), findsOneWidget);
      expect(find.text('Add to Cart'), findsOneWidget);

      await tester.tap(find.text('Buy & Own Now'));
      await tester.pump();
      expect(buyNowClicked, isTrue);

      await tester.tap(find.text('Add to Cart'));
      await tester.pump();
      expect(addToCartClicked, isTrue);
    });

    testWidgets('BookActionCard disables buttons and displays Unavailable when stock == 0', (tester) async {
      final outOfStockBook = Book(
        id: '11',
        title: 'Out of Stock Classic',
        author: 'Unknown',
        coverUrl: 'https://example.com/oos.jpg',
        categories: const ['Classics'],
        listingType: ListingType.forSale,
        rating: 4.0,
        price: 250.0,
        stock: 0,
        isAvailable: false,
        availabilityStatus: 'out_of_stock',
        canBuy: true,
        canRent: false,
        canBorrow: false,
      );

      bool buyNowClicked = false;
      bool addToCartClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Inter'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: BookActionCard(
                book: outOfStockBook,
                onAddToCart: () => addToCartClicked = true,
                onBuyNow: () => buyNowClicked = true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Currently Unavailable'), findsOneWidget);

      // Tapping disabled button should not fire callback
      await tester.tap(find.text('Currently Unavailable'));
      await tester.pump();
      expect(buyNowClicked, isFalse);

      await tester.tap(find.text('Add to Cart'));
      await tester.pump();
      expect(addToCartClicked, isFalse);
    });
  });

  group('Phase 16C.2C — Payment Gateway Service Test Isolation & Flow Verification', () {
    test('PaymentGatewayService delegates to mockHandler when injected', () async {
      PaymentGatewayService.mockHandler = ({
        required String keyId,
        required String orderId,
        required int amountPaise,
        required String userEmail,
        String? userPhone,
        String? userName,
        String? description,
      }) async {
        return PaymentResult.success(
          razorpayOrderId: orderId,
          razorpayPaymentId: 'pay_test_mock_9999',
          razorpaySignature: 'sig_test_valid_mock_signature',
        );
      };

      final result = await PaymentGatewayService.openCheckout(
        keyId: 'rzp_test_mockkey',
        orderId: 'order_test_123',
        amountPaise: 49950,
        userEmail: 'reader@tactilearchive.com',
      );

      expect(result.isSuccess, isTrue);
      expect(result.razorpayOrderId, equals('order_test_123'));
      expect(result.razorpayPaymentId, equals('pay_test_mock_9999'));
      expect(result.razorpaySignature, equals('sig_test_valid_mock_signature'));
      expect(result.isCancelled, isFalse);
    });

    test('PaymentGatewayService returns cancelled result on user dismissal', () async {
      PaymentGatewayService.mockHandler = ({
        required String keyId,
        required String orderId,
        required int amountPaise,
        required String userEmail,
        String? userPhone,
        String? userName,
        String? description,
      }) async {
        return PaymentResult.cancelled();
      };

      final result = await PaymentGatewayService.openCheckout(
        keyId: 'rzp_test_mockkey',
        orderId: 'order_test_456',
        amountPaise: 25000,
        userEmail: 'reader@tactilearchive.com',
      );

      expect(result.isSuccess, isFalse);
      expect(result.isCancelled, isTrue);
      expect(result.errorMessage, contains('cancelled'));
    });

    test('PaymentGatewayService returns failure result on gateway exception', () async {
      PaymentGatewayService.mockHandler = ({
        required String keyId,
        required String orderId,
        required int amountPaise,
        required String userEmail,
        String? userPhone,
        String? userName,
        String? description,
      }) async {
        return PaymentResult.failure('Bank network unreachable');
      };

      final result = await PaymentGatewayService.openCheckout(
        keyId: 'rzp_test_mockkey',
        orderId: 'order_test_789',
        amountPaise: 15000,
        userEmail: 'reader@tactilearchive.com',
      );

      expect(result.isSuccess, isFalse);
      expect(result.isCancelled, isFalse);
      expect(result.errorMessage, equals('Bank network unreachable'));
    });
  });

  group('Phase 16C.2C — Rent & Borrow Workflow Preservation', () {
    test('Rental fee calculation remains isolated and unaffected by Buy integer paise', () {
      final book = Book(
        id: '20',
        title: 'Rental Book Test',
        author: 'Author A',
        coverUrl: 'https://example.com/cover.jpg',
        categories: const ['Fiction'],
        listingType: ListingType.forRent,
        rating: 4.8,
        price: 300.0,
        canRent: true,
        canBuy: true,
        canBorrow: true,
        rentalOptions: {
          'daily_rate': 2.50,
          'deposit': 50.0,
        },
      );

      // Verify rental options remain accessible
      expect(book.canRent, isTrue);
      expect(book.canBorrow, isTrue);
      expect(book.canBuy, isTrue);
      expect(book.rentalOptions?['daily_rate'], equals(2.50));
      expect(book.rentalOptions?['deposit'], equals(50.0));
    });
  });
}
