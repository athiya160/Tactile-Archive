import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:libri_flow/features/auth/presentation/pages/register_page.dart';
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
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Lending & Provider Registration UI Tests', () {
    const testSize = Size(800, 1200);

    testWidgets('Step 1 displays "I want to sell or lend books" card and selects provider role when tapped', (tester) async {
      tester.view.physicalSize = testSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const RegisterPage(), testSize));
      await tester.pumpAndSettle();

      // Verify all 3 options are displayed on Step 1
      expect(find.text("I'm a Student"), findsOneWidget);
      expect(find.text("I'm a Reader"), findsOneWidget);
      expect(find.text('I want to sell or lend books'), findsOneWidget);

      // Initially student is default
      expect(find.text('Continue to Student Signup'), findsOneWidget);

      // Ensure visible and tap "I want to sell or lend books"
      final providerFinder = find.text('I want to sell or lend books');
      await tester.ensureVisible(providerFinder);
      await tester.pumpAndSettle();
      await tester.tap(providerFinder);
      await tester.pumpAndSettle();

      // Verify button now reflects Lender signup
      expect(find.text('Continue to Lender Signup'), findsOneWidget);

      // Ensure button visible and tap "Continue to Lender Signup" to transition to Step 2
      final continueBtnFinder = find.text('Continue to Lender Signup');
      await tester.ensureVisible(continueBtnFinder);
      await tester.pumpAndSettle();
      await tester.tap(continueBtnFinder);
      await tester.pumpAndSettle();

      // Verify Step 2 shows Provider branding and fields
      expect(find.text('Experience: Book Provider (Lender / Seller)'), findsOneWidget);
      expect(find.text('Create Provider Account'), findsNWidgets(2)); // Title & button
      expect(tester.takeException(), isNull);
    });

    testWidgets('RegisterPage initialized with UserRole.provider opens directly in Provider mode on Step 2', (tester) async {
      tester.view.physicalSize = testSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const RegisterPage(role: UserRole.provider), testSize));
      await tester.pumpAndSettle();

      // Verify it opens directly into Step 2 with Provider branding
      expect(find.text('Experience: Book Provider (Lender / Seller)'), findsOneWidget);
      expect(find.text('Create Provider Account'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });
}
