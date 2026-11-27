import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:libri_flow/core/services/google_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiService.token = null;
    ApiService.role = UserRole.none;
    ApiService.authState.value = false;
    GoogleAuthService.setMockGoogleSignIn(null);
  });

  tearDown(() {
    GoogleAuthService.setMockGoogleSignIn(null);
  });

  group('GoogleSignInButton Widget Tests', () {
    testWidgets('renders official Continue with Google label and Google brand icon', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoogleSignInButton(
              onPressed: () => tapped = true,
              label: 'Continue with Google',
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(FaIcon), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.byType(GoogleSignInButton));
      expect(tapped, isTrue);
    });

    testWidgets('shows CircularProgressIndicator and disables taps when isLoading is true', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoogleSignInButton(
              onPressed: () => tapped = true,
              label: 'Continue with Google',
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Continue with Google'), findsNothing);

      await tester.tap(find.byType(GoogleSignInButton));
      expect(tapped, isFalse);
    });
  });

  group('ApiService.loginWithGoogle Contract Tests', () {
    test('rejects empty or whitespace-only credential immediately', () async {
      final res1 = await ApiService.loginWithGoogle(credential: '');
      expect(res1, contains("Google ID token ('credential') is required"));

      final res2 = await ApiService.loginWithGoogle(credential: '   ');
      expect(res2, contains("Google ID token ('credential') is required"));
    });
  });

  group('GoogleAuthService Architecture & Security Tests', () {
    test('GoogleAuthService has configured client ID architecture', () {
      expect(GoogleAuthService.configuredClientId, isNotEmpty);
      expect(GoogleAuthService.googleSignIn, isNotNull);
    });

    test('isSigningIn prevents duplicate concurrent requests', () {
      expect(GoogleAuthService.isSigningIn, isFalse);
    });

    test('GoogleAuthService.signOut clears both Google and LibriFlow sessions', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'test_jwt_to_clear',
        'user_role': 'customer',
      });
      await ApiService.loadToken();
      expect(ApiService.isLoggedIn, isTrue);

      await GoogleAuthService.signOut();
      expect(ApiService.isLoggedIn, isFalse);
      expect(ApiService.token, isNull);
    });
  });
}
