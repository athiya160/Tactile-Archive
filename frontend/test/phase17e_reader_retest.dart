import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:libri_flow/core/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PHASE 17E — READER SESSION RETEST (14-STEP VERIFICATION)', () {
    test('1. Fresh app starts unauthenticated and routes to marketplace HomePage', () async {
      SharedPreferences.setMockInitialValues({});
      ApiService.token = null;
      ApiService.role = UserRole.none;
      ApiService.userType = UserType.reader;
      ApiService.authState.value = false;
      ApiService.roleState.value = UserRole.none;
      ApiService.userTypeState.value = UserType.reader;
      ApiService.onboardingCompleted = false;

      await ApiService.loadToken();

      expect(ApiService.isLoggedIn, isFalse);
      expect(ApiService.role, equals(UserRole.none));
      expect(ApiService.userType, equals(UserType.reader));

      final decision = AppRouter.handleRedirect(
        loc: '/',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(decision, isNull, reason: 'Fresh app on / must stay on marketplace HomePage');
    });

    test('2 & 3. Register Customer -> Reader & Login', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'reader_jwt_token_phase17e',
        'user_role': 'customer',
        'user_persona': 'reader',
        'user_type': 'reader',
        'user_name': 'Sarah Reader',
        'onboarding_completed': true,
      });

      await ApiService.loadToken();

      expect(ApiService.isLoggedIn, isTrue);
      expect(ApiService.role, equals(UserRole.customer));
      expect(ApiService.userType, equals(UserType.reader));
      expect(ApiService.userName, equals('Sarah Reader'));
    });

    test('4. Verify Reader dashboard on login', () async {
      final loginRedirect = AppRouter.handleRedirect(
        loc: '/login',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(loginRedirect, equals('/reader'), reason: 'Reader on /login must redirect to /reader');

      final homeDecision = AppRouter.handleRedirect(
        loc: '/',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(homeDecision, equals('/reader'), reason: 'Reader on / must redirect to /reader dashboard');
    });

    test('5, 6, 7. Kill application, reopen, and verify marketplace HomePage again', () async {
      // Step 5: Simulate OS process termination (clear all in-memory static state)
      ApiService.token = null;
      ApiService.role = UserRole.none;
      ApiService.userType = UserType.reader;
      ApiService.userName = null;
      ApiService.authState.value = false;
      ApiService.roleState.value = UserRole.none;

      // Step 6: Reopen application (load persisted token & role from SharedPreferences)
      await ApiService.loadToken();

      // Step 7: Verify marketplace HomePage again
      expect(ApiService.isLoggedIn, isTrue);
      expect(ApiService.role, equals(UserRole.customer));
      expect(ApiService.userType, equals(UserType.reader));
      expect(ApiService.userName, equals('Sarah Reader'));

      final homeAfterReopen = AppRouter.handleRedirect(
        loc: '/',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(homeAfterReopen, equals('/reader'), reason: 'Reopened Reader app on / must redirect to /reader dashboard');
    });

    test('8. Navigate Browse', () async {
      final browseDecision = AppRouter.handleRedirect(
        loc: '/browse',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(browseDecision, isNull, reason: 'Reader can browse catalog freely');
    });

    test('9. Navigate Book Details', () async {
      final bookDetailsDecision = AppRouter.handleRedirect(
        loc: '/book/1',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(bookDetailsDecision, isNull, reason: 'Reader can view book details');
    });

    test('10. Navigate Favorites', () async {
      final favsDecision = AppRouter.handleRedirect(
        loc: '/favorites',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(favsDecision, isNull, reason: 'Reader can view favorites');
    });

    test('11. Navigate Profile', () async {
      final profileDecision = AppRouter.handleRedirect(
        loc: '/profile',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(profileDecision, isNull, reason: 'Reader can access profile');
    });

    test('12. Logout', () async {
      await ApiService.logout();

      expect(ApiService.isLoggedIn, isFalse);
      expect(ApiService.token, isNull);
      expect(ApiService.role, equals(UserRole.none));
      expect(ApiService.userType, equals(UserType.reader));
      expect(ApiService.userName, isNull);
    });

    test('13 & 14. Restart application and verify public marketplace HomePage', () async {
      // Step 13: Restart application (wipe in-memory state and reload SharedPreferences)
      ApiService.token = null;
      ApiService.role = UserRole.none;
      ApiService.userType = UserType.reader;
      ApiService.authState.value = false;
      ApiService.roleState.value = UserRole.none;

      await ApiService.loadToken();

      // Step 14: Verify public marketplace HomePage
      expect(ApiService.isLoggedIn, isFalse);
      expect(ApiService.role, equals(UserRole.none));

      final publicHome = AppRouter.handleRedirect(
        loc: '/',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(publicHome, isNull, reason: 'Logged-out user on / stays on public marketplace HomePage');
    });
  });
}
