import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/features/auth/presentation/pages/forgot_password_page.dart';

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

Widget createTestWidget({required Size screenSize}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: screenSize),
      child: const SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: ForgotPasswordPage(),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  group('Forgot Password Page - Responsive & Functional Tests', () {
    testWidgets('1. Mobile View (390x844): Renders properly without overflow', (tester) async {
      const mobileSize = Size(390, 844);
      tester.view.physicalSize = mobileSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(screenSize: mobileSize));
      await tester.pumpAndSettle();

      // Verify mobile header
      expect(find.text('The Tactile Archive'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Verify title & initial mode (Email Reset Link)
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text("We'll email you a link to reset your password."), findsOneWidget);
      expect(find.text('Email Reset Link'), findsOneWidget);
      expect(find.text('Instant OTP Code'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Sign In')),
        findsOneWidget,
      );

      // Verify NO RenderFlex overflow occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. Mobile View: Mode switching and OTP controls appear without overflow', (tester) async {
      const mobileSize = Size(390, 844);
      tester.view.physicalSize = mobileSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(screenSize: mobileSize));
      await tester.pumpAndSettle();

      // Tap "Instant OTP Code" chip
      await tester.tap(find.text('Instant OTP Code'));
      await tester.pumpAndSettle();

      // Verify OTP mode UI elements
      expect(find.text('Email or Phone Number'), findsOneWidget);
      expect(find.text('Send 6-Digit OTP Code'), findsOneWidget);
      expect(find.text('Reset your password instantly using a 6-digit OTP code.'), findsOneWidget);

      // Verify NO RenderFlex overflow occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. Mobile View: Validation triggers when field is empty', (tester) async {
      const mobileSize = Size(390, 844);
      tester.view.physicalSize = mobileSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(screenSize: mobileSize));
      await tester.pumpAndSettle();

      // Click "Send Reset Link" with empty field
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      // Expect validation error
      expect(find.text('Enter your email address'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('4. Laptop View (1440x900): Renders desktop 2-column layout', (tester) async {
      const laptopSize = Size(1440, 900);
      tester.view.physicalSize = laptopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(screenSize: laptopSize));
      await tester.pumpAndSettle();

      // Verify left branding hero column (only present on desktop/laptop)
      expect(find.text('Get back to your books.'), findsOneWidget);
      expect(
        find.text(
          "Don't let a forgotten password stop you from discovering affordable books from readers near you.",
        ),
        findsOneWidget,
      );

      // Verify right form column
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Email Reset Link'), findsOneWidget);
      expect(find.text('Instant OTP Code'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);

      // Verify NO overflow on desktop
      expect(tester.takeException(), isNull);
    });

    testWidgets('5. Laptop View: Mode switching and interaction works smoothly', (tester) async {
      const laptopSize = Size(1440, 900);
      tester.view.physicalSize = laptopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(screenSize: laptopSize));
      await tester.pumpAndSettle();

      // Tap "Instant OTP Code" chip
      await tester.tap(find.text('Instant OTP Code'));
      await tester.pumpAndSettle();

      expect(find.text('Email or Phone Number'), findsOneWidget);
      expect(find.text('Send 6-Digit OTP Code'), findsOneWidget);

      // Tap back to "Email Reset Link"
      await tester.tap(find.text('Email Reset Link'));
      await tester.pumpAndSettle();

      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
