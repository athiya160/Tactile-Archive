import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:libri_flow/features/auth/presentation/pages/auth_landing_page.dart';
import 'package:libri_flow/features/library/presentation/widgets/rentals_tab.dart';
import 'package:libri_flow/features/library/domain/entities/rental_item.dart';
import 'package:libri_flow/core/widgets/floating_chatbot.dart';
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

final List<RentalItem> _mockRentalList = [
  const RentalItem(
    id: '1',
    title: 'The Alchemist',
    author: 'Paulo Coelho',
    coverUrl: 'https://images.unsplash.com/photo-1544947950-fa07a98d237f',
    progress: 0.64,
    dueLabel: 'Due in 2d',
  ),
  const RentalItem(
    id: '2',
    title: 'A Moveable Feast',
    author: 'Ernest Hemingway',
    coverUrl: 'https://images.unsplash.com/photo-1512820790803-83ca734da794',
    progress: 0.12,
    dueLabel: 'Oct 24',
  ),
  const RentalItem(
    id: '3',
    title: 'Kafka on the Shore',
    author: 'Haruki Murakami',
    coverUrl: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c',
    progress: 0.85,
    dueLabel: 'Due Tomorrow',
  ),
];

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'mock_token',
      'user_role': 'customer',
      'user_persona': 'reader',
      'user_name': 'Athiya Tabassum',
    });
    ApiService.token = 'mock_token';
  });

  group('Launch Gate UI Regression Tests (Moto G35 / Mobile Viewports)', () {
    const motoG35Size = Size(360, 800); // Standard Moto G35 viewport

    testWidgets('1. AuthLandingPage renders with ZERO horizontal overflow on Moto G35', (tester) async {
      tester.view.physicalSize = motoG35Size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const AuthLandingPage(), motoG35Size));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AuthLandingPage), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'AuthLandingPage had overflow');
    });

    testWidgets('2. RentalsTab renders 3 active rentals with ZERO bottom overflow on Moto G35', (tester) async {
      tester.view.physicalSize = motoG35Size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(
        Scaffold(
          body: RentalsTab(rentals: _mockRentalList),
          floatingActionButton: const FloatingChatbot(),
        ),
        motoG35Size,
      ));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(RentalsTab), findsOneWidget);
      expect(find.byType(FloatingChatbot), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'RentalsTab had overflow');
    });

    testWidgets('3. RentalsTab supports scrolling to reveal full content past FAB', (tester) async {
      tester.view.physicalSize = motoG35Size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(
        Scaffold(
          body: RentalsTab(rentals: _mockRentalList),
          floatingActionButton: const FloatingChatbot(),
        ),
        motoG35Size,
      ));
      await tester.pump(const Duration(milliseconds: 300));

      // Drag to scroll down past the floating button
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull, reason: 'Scrolling caused overflow');
    });
  });
}
