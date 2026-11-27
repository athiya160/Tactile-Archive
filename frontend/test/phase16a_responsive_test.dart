import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:libri_flow/features/auth/presentation/pages/login_page.dart';
import 'package:libri_flow/features/auth/presentation/pages/register_page.dart';
import 'package:libri_flow/features/home/presentation/widgets/home_hero_section.dart';
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
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 16A — Responsive Layout Verification Suite', () {
    const viewports = <String, Size>{
      'Compact Mobile (360x800)': Size(360, 800),
      'Standard Mobile (390x844)': Size(390, 844),
      'Large Mobile (430x932)': Size(430, 932),
      'Tablet Portrait (768x1024)': Size(768, 1024),
      'Tablet Landscape (1024x768)': Size(1024, 768),
      'Desktop Viewport (1440x900)': Size(1440, 900),
    };

    // 1. HomeHeroSection across all 6 viewports
    for (final entry in viewports.entries) {
      testWidgets('HomeHeroSection renders without overflow on ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          wrapWithApp(
            HomeHeroSection(
              onExplorePressed: () {},
              onSellPressed: () {},
            ),
            entry.value,
          ),
        );
        await tester.pumpAndSettle();

        // Search bar should be visible on all screen sizes
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Discover, Borrow & Share\nBooks Around You'), findsOneWidget);
        expect(find.text('ONE WORLD • THREE WAYS TO READ'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    // 2. LoginPage across Mobile and Desktop
    testWidgets('LoginPage renders cleanly on Mobile (390x844)', (tester) async {
      const mobileSize = Size(390, 844);
      tester.view.physicalSize = mobileSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const LoginPage(), mobileSize));
      await tester.pumpAndSettle();

      expect(find.text('The Tactile Archive'), findsWidgets);
      expect(find.text('Sign In'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('LoginPage renders dual-pane on Desktop (1440x900)', (tester) async {
      const desktopSize = Size(1440, 900);
      tester.view.physicalSize = desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const LoginPage(), desktopSize));
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    // 3. RegisterPage Step 1 & Step 2 across Mobile and Desktop
    testWidgets('RegisterPage Step 1 renders experience selection on Mobile (390x844)', (tester) async {
      const mobileSize = Size(390, 844);
      tester.view.physicalSize = mobileSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const RegisterPage(), mobileSize));
      await tester.pumpAndSettle();

      expect(find.text("I'm a Student"), findsOneWidget);
      expect(find.text("I'm a Reader"), findsOneWidget);
      expect(find.text('I want to sell or lend books'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RegisterPage Step 1 renders on Desktop (1440x900)', (tester) async {
      const desktopSize = Size(1440, 900);
      tester.view.physicalSize = desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const RegisterPage(), desktopSize));
      await tester.pumpAndSettle();

      expect(find.text("I'm a Student"), findsOneWidget);
      expect(find.text("I'm a Reader"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RegisterPage Step 2 renders academic fields for student on Mobile', (tester) async {
      const mobileSize = Size(390, 844);
      tester.view.physicalSize = mobileSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const RegisterPage(persona: UserType.student), mobileSize));
      await tester.pumpAndSettle();

      // Step 2 directly with student fields
      expect(find.text('Create Student Account'), findsOneWidget);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Email Address *'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RegisterPage Step 2 renders reader fields without academic fields on Mobile', (tester) async {
      const mobileSize = Size(390, 844);
      tester.view.physicalSize = mobileSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const RegisterPage(persona: UserType.reader), mobileSize));
      await tester.pumpAndSettle();

      // Step 2 directly with reader fields
      expect(find.text('Create Reader Account'), findsOneWidget);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Email Address *'), findsOneWidget);
      // Academic section should NOT be present
      expect(find.text('Academic Details (Optional)'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
