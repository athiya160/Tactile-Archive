import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:libri_flow/core/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 16 — Startup and Hero Routing Verification', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ApiService.logout();
    });

    test('A. logout -> app opens -> marketplace hero (root / returns null)', () async {
      // 1. Ensure logged out state
      await ApiService.logout();
      expect(ApiService.isLoggedIn, isFalse);
      expect(ApiService.role, equals(UserRole.none));

      // 2. App startup with no session
      await ApiService.loadToken();
      expect(ApiService.isLoggedIn, isFalse);

      // 3. Router redirect check on root '/'
      final redirect = AppRouter.handleRedirect(
        loc: '/',
        isAuth: ApiService.isLoggedIn,
        isGuest: ApiService.isGuest,
        userType: ApiService.userType,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );

      // null indicates GoRouter stays on '/' which renders the marketplace HomePage with hero
      expect(redirect, isNull, reason: 'Unauthenticated user on / must stay on / (marketplace HomePage hero)');
    });

    test('B. Reader login -> redirects to /reader dashboard', () async {
      // 1. Set up Reader session in SharedPreferences
      SharedPreferences.setMockInitialValues({
        'auth_token': 'reader_jwt_token_hero_test',
        'user_role': 'customer',
        'user_persona': 'reader',
        'user_name': 'Reader Hero Test',
        'onboarding_completed': true,
      });

      // 2. App startup / login loads session
      await ApiService.loadToken();
      expect(ApiService.isLoggedIn, isTrue);
      expect(ApiService.role, equals(UserRole.customer));
      expect(ApiService.userType, equals(UserType.reader));

      // 3. Router redirect check on root '/'
      final redirect = AppRouter.handleRedirect(
        loc: '/',
        isAuth: ApiService.isLoggedIn,
        isGuest: ApiService.isGuest,
        userType: ApiService.userType,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );

      expect(redirect, equals('/reader'), reason: 'Authenticated Reader on / must redirect to /reader dashboard');
    });

    test('C. Provider login -> Provider Operating Hub (/provider)', () async {
      // 1. Set up Provider session in SharedPreferences
      SharedPreferences.setMockInitialValues({
        'auth_token': 'provider_jwt_token_hero_test',
        'user_role': 'provider',
        'user_name': 'Provider Hero Test',
        'onboarding_completed': true,
      });

      // 2. App startup / login loads session
      await ApiService.loadToken();
      expect(ApiService.isLoggedIn, isTrue);
      expect(ApiService.role, equals(UserRole.provider));

      // 3. Router redirect check on root '/'
      final redirect = AppRouter.handleRedirect(
        loc: '/',
        isAuth: ApiService.isLoggedIn,
        isGuest: ApiService.isGuest,
        userType: ApiService.userType,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );

      expect(redirect, equals('/provider'), reason: 'Authenticated Provider on / must redirect to /provider (Provider Operating Hub)');
    });

    test('D. logout -> marketplace hero again', () async {
      // 1. Start from Provider session
      SharedPreferences.setMockInitialValues({
        'auth_token': 'provider_jwt_token_hero_test',
        'user_role': 'provider',
        'user_name': 'Provider Hero Test',
        'onboarding_completed': true,
      });
      await ApiService.loadToken();
      expect(ApiService.isLoggedIn, isTrue);

      // 2. User logs out
      await ApiService.logout();
      expect(ApiService.isLoggedIn, isFalse);
      expect(ApiService.role, equals(UserRole.none));
      expect(ApiService.token, isNull);

      // 3. Router redirect check on root '/' after logout
      final redirect = AppRouter.handleRedirect(
        loc: '/',
        isAuth: ApiService.isLoggedIn,
        isGuest: ApiService.isGuest,
        userType: ApiService.userType,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );

      expect(redirect, isNull, reason: 'After logout, root / must stay on / (marketplace HomePage hero)');
    });
  });
}
