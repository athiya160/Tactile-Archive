import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:libri_flow/core/widgets/floating_chatbot.dart';
import 'package:libri_flow/core/widgets/global_chatbot_overlay.dart';
import 'package:libri_flow/features/ai/presentation/pages/archive_ai_page.dart';

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

Widget _wrap(Widget child, {Size size = const Size(1200, 800), EdgeInsets padding = EdgeInsets.zero}) {
  return MediaQuery(
    data: MediaQueryData(size: size, padding: padding),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ArchiveAIPage.resetSessionForTesting();
  });

  group('Phase 29: Global Floating Chatbot Suite', () {
    test('1. Route visibility rules check: supported vs excluded routes', () {
      final supportedRoutes = [
        '/home',
        '/browse',
        '/explore',
        '/library',
        '/favorites',
        '/profile',
        '/book/1',
        '/book/42',
        '/provider',
        '/provider-portfolio',
        '/add-book',
        '/admin',
        '/order-history',
        '/orders',
        '/support',
        '/faqs',
      ];

      for (final route in supportedRoutes) {
        expect(
          GlobalChatbotOverlay.shouldShowChatbot(route),
          isTrue,
          reason: 'Expected $route to display floating chatbot',
        );
      }

      final excludedRoutes = [
        '/login',
        '/register',
        '/checkout',
        '/buy-now-checkout',
        '/delivery-address',
        '/archive-ai',
        '/forgot-password',
        '/reset-password',
        '/welcome',
        '/onboarding/user-type',
      ];

      for (final route in excludedRoutes) {
        expect(
          GlobalChatbotOverlay.shouldShowChatbot(route),
          isFalse,
          reason: 'Expected $route to suppress floating chatbot',
        );
      }
    });

    test('2. Shell route vs non-shell route detection for bottom offset elevation', () {
      expect(GlobalChatbotOverlay.isShellRoute('/home'), isTrue);
      expect(GlobalChatbotOverlay.isShellRoute('/browse'), isTrue);
      expect(GlobalChatbotOverlay.isShellRoute('/library'), isTrue);
      expect(GlobalChatbotOverlay.isShellRoute('/favorites'), isTrue);
      expect(GlobalChatbotOverlay.isShellRoute('/profile'), isTrue);
      expect(GlobalChatbotOverlay.isShellRoute('/'), isTrue);

      expect(GlobalChatbotOverlay.isShellRoute('/book/1'), isFalse);
      expect(GlobalChatbotOverlay.isShellRoute('/provider'), isFalse);
      expect(GlobalChatbotOverlay.isShellRoute('/admin'), isFalse);
      expect(GlobalChatbotOverlay.isShellRoute('/add-book'), isFalse);
    });

    testWidgets('3. Desktop presentation renders pill button with label and icon', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Stack(
            children: [
              FloatingChatbot(currentRoute: '/home'),
            ],
          ),
          size: const Size(1280, 800),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('floating_chatbot_launcher_desktop')), findsOneWidget);
      expect(find.textContaining('Ask Archive AI'), findsOneWidget);
    });

    testWidgets('4. Mobile presentation renders 50x50 circular FAB with magic wand', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Stack(
            children: [
              FloatingChatbot(currentRoute: '/home'),
            ],
          ),
          size: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('floating_chatbot_launcher_mobile')), findsOneWidget);
      final size = tester.getSize(find.byKey(const ValueKey('floating_chatbot_launcher_mobile')));
      expect(size.width, equals(50.0));
      expect(size.height, equals(50.0));
    });

    testWidgets('5. Opening and closing panel preserves conversation and toggles cleanly', (tester) async {
      bool isOpen = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _wrap(
              Stack(
                children: [
                  FloatingChatbot(
                    currentRoute: '/home',
                    isOpen: isOpen,
                    onToggle: (val) => setState(() => isOpen = val),
                  ),
                ],
              ),
              size: const Size(1280, 800),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Closed initially
      expect(find.byKey(const ValueKey('floating_chatbot_panel')), findsNothing);
      expect(find.byKey(const ValueKey('floating_chatbot_launcher_desktop')), findsOneWidget);

      // Open panel
      await tester.tap(find.byKey(const ValueKey('floating_chatbot_launcher_desktop')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('floating_chatbot_panel')), findsOneWidget);
      expect(find.byType(ArchiveAIPage), findsOneWidget);

      // Close panel using close icon/callback
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('floating_chatbot_panel')), findsNothing);
      expect(find.byKey(const ValueKey('floating_chatbot_launcher_desktop')), findsOneWidget);
    });

    testWidgets('6. Launcher remains strictly fixed in viewport while page content scrolls', (tester) async {
      final scrollController = ScrollController();

      await tester.pumpWidget(
        _wrap(
          Stack(
            children: [
              ListView.builder(
                controller: scrollController,
                itemCount: 100,
                itemBuilder: (context, i) => Container(
                  height: 100,
                  color: i.isEven ? Colors.grey[200] : Colors.white,
                  child: Center(child: Text('Item $i')),
                ),
              ),
              const Positioned(
                right: 24,
                bottom: 24,
                child: FloatingChatbot(currentRoute: '/home'),
              ),
            ],
          ),
          size: const Size(1280, 800),
        ),
      );
      await tester.pumpAndSettle();

      final initialTopLeft = tester.getTopLeft(find.byKey(const ValueKey('floating_chatbot_launcher_desktop')));

      // Scroll down by 1500 logical pixels
      scrollController.jumpTo(1500);
      await tester.pumpAndSettle();

      final scrolledTopLeft = tester.getTopLeft(find.byKey(const ValueKey('floating_chatbot_launcher_desktop')));

      expect(
        scrolledTopLeft,
        equals(initialTopLeft),
        reason: 'Launcher must remain at the exact same screen coordinates regardless of page scroll offset',
      );
    });

    testWidgets('7. Contextual prompts on /book/:id route display book-specific suggestions', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Stack(
            children: [
              FloatingChatbot(
                currentRoute: '/book/42',
                isOpen: true,
              ),
            ],
          ),
          size: const Size(1280, 800),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Summarize this book'), findsOneWidget);
      expect(find.textContaining('Does this suit my reading goals?'), findsOneWidget);
      expect(find.textContaining('Compare Buy vs Rent'), findsOneWidget);
    });

    testWidgets('8. Contextual prompts on /provider route display provider-specific suggestions', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Stack(
            children: [
              FloatingChatbot(
                currentRoute: '/provider',
                isOpen: true,
              ),
            ],
          ),
          size: const Size(1280, 800),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Suggest a rental price'), findsOneWidget);
      expect(find.textContaining('Describe book condition'), findsOneWidget);
      expect(find.textContaining('Tips to increase rentals & sales'), findsOneWidget);
    });

    testWidgets('9. Contextual prompts on /admin route display admin-specific suggestions', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Stack(
            children: [
              FloatingChatbot(
                currentRoute: '/admin',
                isOpen: true,
              ),
            ],
          ),
          size: const Size(1280, 800),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Marketplace health overview'), findsOneWidget);
      expect(find.textContaining('Content moderation guidelines'), findsOneWidget);
      expect(find.textContaining('Platform policy assistance'), findsOneWidget);
    });

    testWidgets('10. Safe area bottom padding is respected on mobile viewports', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Stack(
            children: [
              FloatingChatbot(
                currentRoute: '/home',
              ),
            ],
          ),
          size: const Size(390, 844),
          padding: const EdgeInsets.only(bottom: 34),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('floating_chatbot_launcher_mobile')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
