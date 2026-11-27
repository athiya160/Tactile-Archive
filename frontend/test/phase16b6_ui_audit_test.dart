import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:libri_flow/features/auth/presentation/pages/auth_landing_page.dart';
import 'package:libri_flow/features/auth/presentation/pages/login_page.dart';
import 'package:libri_flow/features/auth/presentation/pages/register_page.dart';
import 'package:libri_flow/core/widgets/floating_chatbot.dart';
import 'package:libri_flow/core/widgets/login_required_dialog.dart';
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

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'mock_token',
      'user_role': 'customer',
      'user_persona': 'reader',
      'user_name': 'Test User',
      'active_experience': 'reader',
    });
    ApiService.token = 'mock_token';
    ApiService.userType = UserType.reader;
    ApiService.activeExperience = UserType.reader;
    FlutterError.onError = FlutterError.dumpErrorToConsole;
  });

  void assertNoOverflow(WidgetTester tester, String contextLabel) {
    final dynamic err = tester.takeException();
    if (err != null) {
      debugPrint('=== OVERFLOW DETECTED: $contextLabel ===');
      if (err is FlutterError) {
        for (final d in err.diagnostics) {
          debugPrint(d.toStringDeep());
        }
      } else {
        debugPrint(err.toString());
      }
    }
    expect(err, isNull, reason: '$contextLabel had render overflow');
  }

  group('Phase 16B.6 — UI Audit & Viewport Stability Suite', () {
    const targetViewports = <String, Size>{
      'Small Android (360x800)': Size(360, 800),
      'Standard Android (390x844)': Size(390, 844),
      'Large Android (430x932)': Size(430, 932),
      'Tablet Portrait (768x1024)': Size(768, 1024),
      'Tablet Landscape (1024x768)': Size(1024, 768),
      'Laptop (1366x768)': Size(1366, 768),
      'Desktop (1440x900)': Size(1440, 900),
      'Large Desktop (1920x1080)': Size(1920, 1080),
    };

    for (final entry in targetViewports.entries) {
      testWidgets('AuthLandingPage renders cleanly at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(const AuthLandingPage(), entry.value));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(AuthLandingPage), findsOneWidget);
        assertNoOverflow(tester, 'AuthLandingPage at ${entry.key}');
      });

      testWidgets('LoginPage renders cleanly at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(const LoginPage(), entry.value));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(LoginPage), findsOneWidget);
        assertNoOverflow(tester, 'LoginPage at ${entry.key}');
      });

      testWidgets('RegisterPage Step 1 renders cleanly at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(const RegisterPage(), entry.value));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(RegisterPage), findsOneWidget);
        assertNoOverflow(tester, 'RegisterPage Step 1 at ${entry.key}');
      });

      testWidgets('RegisterPage Step 2 (Student) renders cleanly at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(const RegisterPage(persona: UserType.student), entry.value));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(RegisterPage), findsOneWidget);
        assertNoOverflow(tester, 'RegisterPage Step 2 (Student) at ${entry.key}');
      });

      testWidgets('RegisterPage Step 2 (Reader) renders cleanly at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(const RegisterPage(persona: UserType.reader), entry.value));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(RegisterPage), findsOneWidget);
        assertNoOverflow(tester, 'RegisterPage Step 2 (Reader) at ${entry.key}');
      });
      testWidgets('LoginRequiredDialog renders cleanly at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(const LoginRequiredDialog(), entry.value));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(LoginRequiredDialog), findsOneWidget);
        assertNoOverflow(tester, 'LoginRequiredDialog at ${entry.key}');
      });

      testWidgets('FloatingChatbot renders cleanly at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(const Stack(children: [FloatingChatbot()]), entry.value));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(FloatingChatbot), findsOneWidget);
        assertNoOverflow(tester, 'FloatingChatbot at ${entry.key}');
      });

    }
  });
}
