# -*- coding: utf-8 -*-
"""
Script: apply_phase15_stabilization.py
Applies Task 1 and Task 2 changes for Phase 15 stabilization.
"""

import os
import re

def patch_file(path, old_text, new_text, description):
    print(f"Patching: {description} ({path})")
    with open(path, 'rb') as f:
        content = f.read().decode('utf-8')
    
    # Normalize CRLF vs LF matching
    old_clean = old_text.replace('\r\n', '\n')
    content_clean = content.replace('\r\n', '\n')
    
    if old_clean not in content_clean:
        raise ValueError(f"Target text not found in {path} for {description}")
    
    # Replace in normalized content then restore original line endings style
    has_crlf = '\r\n' in content
    new_clean = new_text.replace('\r\n', '\n')
    content_clean = content_clean.replace(old_clean, new_clean, 1)
    
    if has_crlf:
        final_content = content_clean.replace('\n', '\r\n')
    else:
        final_content = content_clean
        
    with open(path, 'wb') as f:
        f.write(final_content.encode('utf-8'))
    print(f" Successfully patched: {description}")


# 1. Update app_router.dart handleRedirect parameter & implementation
old_app_router = """  /// Persona-aware redirect logic evaluated by GoRouter.
  static String? handleRedirect({
    required String loc,
    required bool isAuth,
    required bool isGuest,
    required UserType userType,
    required UserRole role,
    required bool onboardingCompleted,
  }) {
    // Auth pages
    final authPages = [
      '/welcome',
      '/login',
      '/register',
      '/forgot-password',
      '/reset-password',
      '/onboarding/user-type',
    ];
    final onAuthPage = authPages.any((p) => loc == p || loc.startsWith('$p/'));

    // Public learning & AI tools that must ALWAYS be directly accessible without login
    final publicTools = [
      '/book',
      '/semester-planner',
      '/plans',
      '/study-assistant',
      '/student/study-assistant',
      '/reader/reading-companion',
      '/reading-plan',
      '/mood-match',
      '/shelf-scanner',
      '/archive-ai',
      '/exchange-map',
    ];
    if (publicTools.any((p) => loc == p || loc.startsWith('$p/'))) {
      return null;
    }

    // Protected routes requiring authentication
    final protectedRoutes = [
      '/student',
      '/reader',
      '/onboarding/student-preferences',
      '/onboarding/reader-preferences',
      '/student/onboarding',
      '/provider',
      '/provider-portfolio',
      '/cart',
      '/checkout',
      '/buy-now-checkout',
      '/order-history',
      '/orders',
      '/account-settings',
      '/sell',
      '/add-book',
      '/review',
      '/profile',
    ];
    final isProtected = protectedRoutes.any((p) => loc == p || loc.startsWith('$p/'));

    // 1. Unauthenticated non-guest attempting protected routes -> redirect to /welcome (Login/Signup)
    if (!isAuth && !isGuest && isProtected) {
      return '/welcome';
    }

    // 2. Reader users must NEVER be forced through student onboarding
    if (loc.startsWith('/onboarding/student-preferences') && userType == UserType.reader) {
      return '/';
    }

    // 3. Student attempting /student dashboard when onboarding is incomplete -> redirect to student onboarding
    if (isAuth && userType == UserType.student && !onboardingCompleted && loc == '/student') {
      return '/onboarding/student-preferences';
    }

    // 4. Authenticated user landing on auth pages (e.g. /login, /register, /welcome)
    if (onAuthPage && isAuth) {
      if (role == UserRole.provider) {
        return '/provider';
      }
      if (ApiService.activeExperience == UserType.student) {
        return '/student';
      }
      return '/reader';
    }

    // 5. Guest landing on /welcome
    if (loc == '/welcome' && isGuest) {
      return '/';
    }

    // 6. Root path ('/') persona-aware routing
    if (loc == '/') {
      if (isAuth) {
        if (role == UserRole.provider) {
          return '/provider';
        }
        if (ApiService.activeExperience == UserType.student) {
          return '/student';
        }
        if (ApiService.activeExperience == UserType.reader) {
          return '/reader';
        }
        return null;
      }
      // Unauthenticated visitor / Guest on '/' -> normal public Home/Browse experience on '/'
      return null;
    }

    // All other direct navigation (e.g. /home, /browse, /categories, /profile, /student, /provider, /ai-concierge, /sell, /cart, /checkout, /orders) is preserved
    return null;
  }"""

new_app_router = """  /// Persona-aware redirect logic evaluated by GoRouter.
  static String? handleRedirect({
    required String loc,
    required bool isAuth,
    required bool isGuest,
    required UserType userType,
    required UserRole role,
    required bool onboardingCompleted,
    UserType? activeExperience,
  }) {
    // Auth pages
    final authPages = [
      '/welcome',
      '/login',
      '/register',
      '/forgot-password',
      '/reset-password',
      '/onboarding/user-type',
    ];
    final onAuthPage = authPages.any((p) => loc == p || loc.startsWith('$p/'));

    // Public learning & AI tools that must ALWAYS be directly accessible without login
    final publicTools = [
      '/book',
      '/semester-planner',
      '/plans',
      '/study-assistant',
      '/student/study-assistant',
      '/reader/reading-companion',
      '/reading-plan',
      '/mood-match',
      '/shelf-scanner',
      '/archive-ai',
      '/exchange-map',
    ];
    if (publicTools.any((p) => loc == p || loc.startsWith('$p/'))) {
      return null;
    }

    // Protected routes requiring authentication
    final protectedRoutes = [
      '/student',
      '/reader',
      '/onboarding/student-preferences',
      '/onboarding/reader-preferences',
      '/student/onboarding',
      '/provider',
      '/provider-portfolio',
      '/cart',
      '/checkout',
      '/buy-now-checkout',
      '/order-history',
      '/orders',
      '/account-settings',
      '/sell',
      '/add-book',
      '/review',
      '/profile',
    ];
    final isProtected = protectedRoutes.any((p) => loc == p || loc.startsWith('$p/'));

    // 1. Unauthenticated non-guest attempting protected routes -> redirect to /welcome (Login/Signup)
    if (!isAuth && !isGuest && isProtected) {
      return '/welcome';
    }

    final exp = activeExperience ?? userType;

    // 2. Reader users must NEVER be forced through student onboarding
    if (loc.startsWith('/onboarding/student-preferences') && exp == UserType.reader) {
      return '/reader';
    }

    // 3. Student attempting /student dashboard when onboarding is incomplete -> redirect to student onboarding
    if (isAuth && exp == UserType.student && !onboardingCompleted && loc == '/student') {
      return '/onboarding/student-preferences';
    }

    // 4. Authenticated user landing on auth pages (e.g. /login, /register, /welcome)
    if (onAuthPage && isAuth) {
      if (role == UserRole.provider) {
        return '/provider';
      }
      if (exp == UserType.student) {
        return onboardingCompleted ? '/student' : '/onboarding/student-preferences';
      }
      return '/reader';
    }

    // 5. Guest landing on /welcome
    if (loc == '/welcome' && isGuest) {
      return '/';
    }

    // 6. Root path ('/') persona-aware routing
    if (loc == '/') {
      if (isAuth) {
        if (role == UserRole.provider) {
          return '/provider';
        }
        if (exp == UserType.student) {
          return onboardingCompleted ? '/student' : '/onboarding/student-preferences';
        }
        if (exp == UserType.reader) {
          return '/reader';
        }
        return null;
      }
      // Unauthenticated visitor / Guest on '/' -> normal public Home/Browse experience on '/'
      return null;
    }

    // All other direct navigation (e.g. /home, /browse, /categories, /profile, /student, /provider, /ai-concierge, /sell, /cart, /checkout, /orders) is preserved
    return null;
  }"""

old_router_redirect = """    redirect: (context, state) => handleRedirect(
      loc: state.matchedLocation,
      isAuth: ApiService.isLoggedIn,
      isGuest: ApiService.isGuest,
      userType: ApiService.userType,
      role: ApiService.role,
      onboardingCompleted: ApiService.onboardingCompleted,
    ),"""

new_router_redirect = """    redirect: (context, state) => handleRedirect(
      loc: state.matchedLocation,
      isAuth: ApiService.isLoggedIn,
      isGuest: ApiService.isGuest,
      userType: ApiService.userType,
      role: ApiService.role,
      onboardingCompleted: ApiService.onboardingCompleted,
      activeExperience: ApiService.activeExperience,
    ),"""

patch_file('frontend/lib/core/router/app_router.dart', old_app_router, new_app_router, "app_router handleRedirect logic")
patch_file('frontend/lib/core/router/app_router.dart', old_router_redirect, new_router_redirect, "app_router pass activeExperience")

# 2. Fix 5 warnings in Phase 15 files
# Warning 1: desktop_top_nav_bar unused import
old_dnav = """import '../services/api_service.dart';
import 'login_required_dialog.dart';
import '../tokens/app_tokens.dart';"""
new_dnav = """import '../services/api_service.dart';
import '../tokens/app_tokens.dart';"""
patch_file('frontend/lib/core/widgets/desktop_top_nav_bar.dart', old_dnav, new_dnav, "desktop_top_nav_bar remove unused import")

# Warning 2: mobile_top_nav_bar unused isProvider
old_mnav = """    final userName = ApiService.userName ?? 'Athiya Tabassum';
    final isProvider = ApiService.isProvider;
    final activeExp = ApiService.activeExperience;"""
new_mnav = """    final userName = ApiService.userName ?? 'Athiya Tabassum';
    final activeExp = ApiService.activeExperience;"""
patch_file('frontend/lib/core/widgets/mobile_top_nav_bar.dart', old_mnav, new_mnav, "mobile_top_nav_bar remove unused isProvider")

# Warning 3: reader_dashboard_page unused design_system import
old_rdash = """import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/api_service.dart';"""
new_rdash = """import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/api_service.dart';"""
patch_file('frontend/lib/features/home/presentation/pages/reader_dashboard_page.dart', old_rdash, new_rdash, "reader_dashboard_page remove unused import")

# Warning 4: profile_page unused isConfirmed
old_prof = """            final isPending = req.stage == BorrowStage.pending;
            final isAccepted = req.stage == BorrowStage.accepted;
            final isConfirmed = req.stage == BorrowStage.confirmed;

            final statusColor = isPending"""
new_prof = """            final isPending = req.stage == BorrowStage.pending;
            final isAccepted = req.stage == BorrowStage.accepted;

            final statusColor = isPending"""
patch_file('frontend/lib/features/profile/presentation/pages/profile_page.dart', old_prof, new_prof, "profile_page remove unused isConfirmed")

# Warning 5: register_page unused _borderLight
old_reg = """  static const Color _textDark = Color(0xFF1A202C);
  static const Color _textLight = Color(0xFF4A5568);
  static const Color _borderLight = Color(0xFFE2E8F0);
  static const Curve _transitionCurve = Cubic(0.25, 0.8, 0.25, 1);"""
new_reg = """  static const Color _textDark = Color(0xFF1A202C);
  static const Color _textLight = Color(0xFF4A5568);
  static const Curve _transitionCurve = Cubic(0.25, 0.8, 0.25, 1);"""
patch_file('frontend/lib/features/auth/presentation/pages/register_page.dart', old_reg, new_reg, "register_page remove unused _borderLight")

# 3. Update tests
# Test File: persona_auth_unit_test.dart
old_pauth_test1 = """    test('1. Reader login: redirects to normal Home experience on /', () {
      // From login page
      final fromLogin = AppRouter.handleRedirect(
        loc: '/login',
        isAuth: true,
        isGuest: false,
        userType: UserType.reader,
        role: UserRole.customer,
        onboardingCompleted: true,
      );
      expect(fromLogin, equals('/'));

      // On root /
      final onRoot = AppRouter.handleRedirect(
        loc: '/',
        isAuth: true,
        isGuest: false,
        userType: UserType.reader,
        role: UserRole.customer,
        onboardingCompleted: true,
      );
      expect(onRoot, isNull, reason: 'Authenticated Reader stays on / (normal Home/Browse experience)');
    });"""

new_pauth_test1 = """    test('1. Reader login: redirects to Reader dashboard on /reader', () {
      // From login page
      final fromLogin = AppRouter.handleRedirect(
        loc: '/login',
        isAuth: true,
        isGuest: false,
        userType: UserType.reader,
        role: UserRole.customer,
        onboardingCompleted: true,
      );
      expect(fromLogin, equals('/reader'));

      // On root /
      final onRoot = AppRouter.handleRedirect(
        loc: '/',
        isAuth: true,
        isGuest: false,
        userType: UserType.reader,
        role: UserRole.customer,
        onboardingCompleted: true,
      );
      expect(onRoot, equals('/reader'), reason: 'Authenticated Reader on / redirects to /reader dashboard');
    });"""
patch_file('frontend/test/persona_auth_unit_test.dart', old_pauth_test1, new_pauth_test1, "persona_auth_unit_test test 1")

old_pauth_test6 = """      // Re-login as Reader
      expect(
        AppRouter.handleRedirect(
          loc: '/login',
          isAuth: true,
          isGuest: false,
          userType: UserType.reader,
          role: UserRole.customer,
          onboardingCompleted: true,
        ),
        equals('/'),
      );"""

new_pauth_test6 = """      // Re-login as Reader
      expect(
        AppRouter.handleRedirect(
          loc: '/login',
          isAuth: true,
          isGuest: false,
          userType: UserType.reader,
          role: UserRole.customer,
          onboardingCompleted: true,
        ),
        equals('/reader'),
      );"""
patch_file('frontend/test/persona_auth_unit_test.dart', old_pauth_test6, new_pauth_test6, "persona_auth_unit_test test 6")

old_pauth_safety = """    test('Safety: Reader is never forced through student onboarding', () {
      final readerAccidentallyOnOnboarding = AppRouter.handleRedirect(
        loc: '/onboarding/student-preferences',
        isAuth: true,
        isGuest: false,
        userType: UserType.reader,
        role: UserRole.customer,
        onboardingCompleted: false,
      );
      expect(readerAccidentallyOnOnboarding, equals('/'));
    });"""

new_pauth_safety = """    test('Safety: Reader is never forced through student onboarding', () {
      final readerAccidentallyOnOnboarding = AppRouter.handleRedirect(
        loc: '/onboarding/student-preferences',
        isAuth: true,
        isGuest: false,
        userType: UserType.reader,
        role: UserRole.customer,
        onboardingCompleted: false,
      );
      expect(readerAccidentallyOnOnboarding, equals('/reader'));
    });"""
patch_file('frontend/test/persona_auth_unit_test.dart', old_pauth_safety, new_pauth_safety, "persona_auth_unit_test safety test")

# Test File: phase16_hero_routing_test.dart
old_hero_test_b = """    test('B. Reader login -> marketplace hero (root / returns null)', () async {
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

      expect(redirect, isNull, reason: 'Authenticated Reader on / must stay on / (marketplace HomePage hero)');
    });"""

new_hero_test_b = """    test('B. Reader login -> redirects to /reader dashboard', () async {
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
    });"""
patch_file('frontend/test/phase16_hero_routing_test.dart', old_hero_test_b, new_hero_test_b, "phase16_hero_routing_test test B")

# Test File: phase17e_reader_retest.dart
old_17e_test4 = """    test('4. Verify marketplace HomePage on login', () async {
      final loginRedirect = AppRouter.handleRedirect(
        loc: '/login',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(loginRedirect, equals('/'), reason: 'Reader on /login must redirect to /');

      final homeDecision = AppRouter.handleRedirect(
        loc: '/',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(homeDecision, isNull, reason: 'Reader on / must stay on marketplace HomePage');
    });"""

new_17e_test4 = """    test('4. Verify Reader dashboard on login', () async {
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
    });"""
patch_file('frontend/test/phase17e_reader_retest.dart', old_17e_test4, new_17e_test4, "phase17e_reader_retest test 4")

old_17e_test5 = """      final homeAfterReopen = AppRouter.handleRedirect(
        loc: '/',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(homeAfterReopen, isNull, reason: 'Reopened Reader app on / must stay on marketplace HomePage');"""

new_17e_test5 = """      final homeAfterReopen = AppRouter.handleRedirect(
        loc: '/',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(homeAfterReopen, equals('/reader'), reason: 'Reopened Reader app on / must redirect to /reader dashboard');"""
patch_file('frontend/test/phase17e_reader_retest.dart', old_17e_test5, new_17e_test5, "phase17e_reader_retest test 5-7")

# Test File: persona_e2e_flow_test.dart
old_e2e_reader = """      // 6. Verify normal Home routing
      final redirectFromLogin = AppRouter.handleRedirect(
        loc: '/login',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(redirectFromLogin, equals('/'), reason: 'Reader login must direct to normal Home (/)');

      final onHome = AppRouter.handleRedirect(
        loc: '/',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(onHome, isNull, reason: 'Reader must stay on Home without redirect loop');"""

new_e2e_reader = """      // 6. Verify Reader dashboard routing
      final redirectFromLogin = AppRouter.handleRedirect(
        loc: '/login',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(redirectFromLogin, equals('/reader'), reason: 'Reader login must direct to Reader dashboard (/reader)');

      final onHome = AppRouter.handleRedirect(
        loc: '/',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(onHome, equals('/reader'), reason: 'Reader on / redirects to /reader dashboard');"""
patch_file('frontend/test/persona_e2e_flow_test.dart', old_e2e_reader, new_e2e_reader, "persona_e2e_flow_test Reader routing")

print("\nAll stabilization patches applied successfully!")
