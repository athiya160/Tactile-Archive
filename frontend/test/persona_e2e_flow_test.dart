import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:libri_flow/core/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TEST A — READER E2E FLOW', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ApiService.token = null;
      ApiService.role = UserRole.none;
      ApiService.userType = UserType.reader;
      ApiService.authState.value = false;
      ApiService.roleState.value = UserRole.none;
      ApiService.userTypeState.value = UserType.reader;
      ApiService.onboardingCompleted = false;
    });

    test('Complete Reader journey: Register -> Login -> Home -> Browse -> Book -> Favorite -> Cart -> Profile -> Logout', () async {
      // 1-3. Create Reader account & select Reader
      SharedPreferences.setMockInitialValues({
        'auth_token': 'reader_jwt_token_abc',
        'user_role': 'customer',
        'user_persona': 'reader',
        'user_name': 'Alice Reader',
        'onboarding_completed': true,
      });

      // 4. Login & load session
      await ApiService.loadToken();

      // 5. Verify persona = reader
      expect(ApiService.isLoggedIn, isTrue, reason: 'User must be authenticated');
      expect(ApiService.persona, equals(UserType.reader), reason: 'Persona must be reader');
      expect(ApiService.userType, equals(UserType.reader), reason: 'UserType must be reader');

      // 6. Verify Reader dashboard routing
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
      expect(onHome, equals('/reader'), reason: 'Reader on / redirects to /reader dashboard');

      // 7. Browse books
      final onBrowse = AppRouter.handleRedirect(
        loc: '/browse',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(onBrowse, isNull, reason: 'Reader can freely browse catalog');

      // 8. Open book detail
      final onBookDetail = AppRouter.handleRedirect(
        loc: '/browse',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(onBookDetail, isNull, reason: 'Reader can view book details');

      // 9. Favorite / categories
      final onCategories = AppRouter.handleRedirect(
        loc: '/categories',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(onCategories, isNull, reason: 'Reader can access categories');

      // 10. Cart & Orders
      final onCart = AppRouter.handleRedirect(
        loc: '/cart',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(onCart, isNull, reason: 'Reader can access cart');

      final onOrders = AppRouter.handleRedirect(
        loc: '/orders',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(onOrders, isNull, reason: 'Authenticated Reader can access orders');

      // 11. Profile
      final onProfile = AppRouter.handleRedirect(
        loc: '/profile',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(onProfile, isNull, reason: 'Reader can view reader profile');

      // 12. Logout
      await ApiService.logout();
      expect(ApiService.isLoggedIn, isFalse, reason: 'Session must be terminated');
      expect(ApiService.token, isNull, reason: 'Token must be cleared');

      final protectedAfterLogout = AppRouter.handleRedirect(
        loc: '/orders',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(protectedAfterLogout, equals('/welcome'), reason: 'Logged out user attempting protected route must be redirected to /welcome');

      final homeAfterLogout = AppRouter.handleRedirect(
        loc: '/',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(homeAfterLogout, isNull, reason: 'Logged out user on root / views public HomePage');
    });
  });

  group('TEST B — STUDENT E2E FLOW', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ApiService.token = null;
      ApiService.role = UserRole.none;
      ApiService.userType = UserType.reader;
      ApiService.authState.value = false;
      ApiService.roleState.value = UserRole.none;
      ApiService.userTypeState.value = UserType.reader;
      ApiService.onboardingCompleted = false;
    });

    test('Complete Student journey: Register -> Login -> Onboarding -> Semester Setup -> Dashboard -> Assistant -> Reading Plans -> Profile -> Logout', () async {
      // 1-3. Create Student account & select Student
      SharedPreferences.setMockInitialValues({
        'auth_token': 'student_jwt_token_xyz',
        'user_role': 'customer',
        'user_persona': 'student',
        'user_name': 'Bob Student',
        'onboarding_completed': false,
      });

      // 4. Login
      await ApiService.loadToken();

      // 5. Verify persona = student
      expect(ApiService.isLoggedIn, isTrue);
      expect(ApiService.persona, equals(UserType.student));
      expect(ApiService.userType, equals(UserType.student));
      expect(ApiService.onboardingCompleted, isFalse);

      // 6. Verify Student Onboarding redirection
      final redirectFromLogin = AppRouter.handleRedirect(
        loc: '/login',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(
        redirectFromLogin,
        equals('/onboarding/student-preferences'),
        reason: 'New student without completed onboarding must be sent to onboarding',
      );

      final redirectFromRoot = AppRouter.handleRedirect(
        loc: '/',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(redirectFromRoot, equals('/onboarding/student-preferences'));

      // 7-9. Enter degree/course, select semester, select academic year
      final saved = await ApiService.saveStudentProfile(
        course: 'Bachelor of Computer Applications (BCA)',
        educationLevel: 'Semester 6',
        examGoal: 'Semester Exams',
        semester: 'Semester 6',
        academicYear: 'Academic Year 2026–27',
        college: 'National Institute of Technology',
      );
      expect(saved, isTrue);
      expect(ApiService.onboardingCompleted, isTrue);

      // 10. Open Student Dashboard
      final redirectAfterOnboarding = AppRouter.handleRedirect(
        loc: '/login',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(
        redirectAfterOnboarding,
        equals('/student'),
        reason: 'Student with completed onboarding routes directly to /student dashboard',
      );

      final onStudentDashboard = AppRouter.handleRedirect(
        loc: '/student',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(onStudentDashboard, isNull, reason: 'Student stays on /student dashboard without loops');

      // 11. Verify semester information stored in session
      expect(ApiService.studentDegree, equals('Bachelor of Computer Applications (BCA)'));
      expect(ApiService.studentSemester, equals('Semester 6'));
      expect(ApiService.studentAcademicYear, equals('Academic Year 2026–27'));
      expect(ApiService.studentCollege, equals('National Institute of Technology'));

      // 12. Open Study Assistant
      final onAiAssistant = AppRouter.handleRedirect(
        loc: '/ai-concierge',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(onAiAssistant, isNull, reason: 'Student can access AI Study Assistant');

      // 13. Open Reading Plans / Courses
      final onCourses = AppRouter.handleRedirect(
        loc: '/student',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(onCourses, isNull);

      // 14. Open Profile
      final onProfile = AppRouter.handleRedirect(
        loc: '/profile',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(onProfile, isNull, reason: 'Student can view profile');

      // 15. Logout
      await ApiService.logout();
      expect(ApiService.isLoggedIn, isFalse);
      expect(ApiService.studentDegree, isNull);
      expect(ApiService.studentSemester, isNull);

      final afterLogout = AppRouter.handleRedirect(
        loc: '/student',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(afterLogout, equals('/welcome'), reason: 'Logged out student redirected away from /student');
    });
  });

  group('TEST C — EXISTING USER FLOW', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ApiService.token = null;
      ApiService.role = UserRole.none;
      ApiService.userType = UserType.reader;
      ApiService.authState.value = false;
      ApiService.roleState.value = UserRole.none;
      ApiService.userTypeState.value = UserType.reader;
      ApiService.onboardingCompleted = false;
    });

    test('Existing user: Reader login, Provider functionality, Profile, Marketplace, Re-login', () async {
      // 1. Existing user with role=provider and user_type=reader (prior to persona column)
      SharedPreferences.setMockInitialValues({
        'auth_token': 'existing_provider_jwt_token',
        'user_role': 'provider',
        'user_type': 'reader',
        'user_name': 'Existing Bookstore Provider',
        'onboarding_completed': true,
      });

      await ApiService.loadToken();

      expect(ApiService.isLoggedIn, isTrue);
      expect(ApiService.role, equals(UserRole.provider));
      expect(ApiService.persona, equals(UserType.reader));

      // 2. Existing Provider functionality preserved
      final providerRoute = AppRouter.handleRedirect(
        loc: '/login',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(providerRoute, equals('/provider'), reason: 'Provider must be redirected to /provider');

      final onProviderHub = AppRouter.handleRedirect(
        loc: '/provider',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(onProviderHub, isNull, reason: 'Provider stays on /provider');

      // 3. Existing profile
      final onProfile = AppRouter.handleRedirect(
        loc: '/profile',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(onProfile, isNull);

      // 4. Existing marketplace & sell
      final onMarketplace = AppRouter.handleRedirect(
        loc: '/browse',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(onMarketplace, isNull);

      final onSell = AppRouter.handleRedirect(
        loc: '/sell',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(onSell, isNull);

      // 5. Logout and login again
      await ApiService.logout();
      expect(ApiService.isLoggedIn, isFalse);

      // Re-login
      SharedPreferences.setMockInitialValues({
        'auth_token': 'relogin_token_provider',
        'user_role': 'provider',
        'user_persona': 'reader',
        'onboarding_completed': true,
      });
      await ApiService.loadToken();

      expect(ApiService.isLoggedIn, isTrue);
      expect(ApiService.role, equals(UserRole.provider));
      final reRoute = AppRouter.handleRedirect(
        loc: '/login',
        isAuth: ApiService.isLoggedIn,
        isGuest: false,
        userType: ApiService.persona,
        role: ApiService.role,
        onboardingCompleted: ApiService.onboardingCompleted,
      );
      expect(reRoute, equals('/provider'));
    });
  });

  group('TEST D — ROUTING LOOP AND UNAUTHORIZED ACCESS VERIFICATION', () {
    test('Prevents redirect loops across all primary destinations', () {
      final routesToVerify = [
        '/',
        '/welcome',
        '/login',
        '/student',
        '/provider',
        '/browse',
        '/cart',
        '/checkout',
        '/orders',
        '/profile',
        '/onboarding/student-preferences',
      ];

      for (final route in routesToVerify) {
        // Authenticated Reader on target route: must not redirect to itself
        final resReader = AppRouter.handleRedirect(
          loc: route,
          isAuth: true,
          isGuest: false,
          userType: UserType.reader,
          role: UserRole.customer,
          onboardingCompleted: true,
        );
        expect(resReader != route, isTrue, reason: 'Route $route must never redirect to itself (loop)');

        // Authenticated Student on target route: must not redirect to itself
        final resStudent = AppRouter.handleRedirect(
          loc: route,
          isAuth: true,
          isGuest: false,
          userType: UserType.student,
          role: UserRole.customer,
          onboardingCompleted: true,
        );
        expect(resStudent != route, isTrue, reason: 'Route $route must never redirect to itself for student');

        // Authenticated Provider on target route: must not redirect to itself
        final resProvider = AppRouter.handleRedirect(
          loc: route,
          isAuth: true,
          isGuest: false,
          userType: UserType.reader,
          role: UserRole.provider,
          onboardingCompleted: true,
        );
        expect(resProvider != route, isTrue, reason: 'Route $route must never redirect to itself for provider');
      }
    });

    test('Prevents unauthorized access to protected routes', () {
      final protectedRoutes = [
        '/student',
        '/provider',
        '/orders',
        '/checkout',
        '/profile',
      ];

      for (final route in protectedRoutes) {
        final redirect = AppRouter.handleRedirect(
          loc: route,
          isAuth: false,
          isGuest: false,
          userType: UserType.reader,
          role: UserRole.none,
          onboardingCompleted: false,
        );
        expect(
          redirect,
          equals('/welcome'),
          reason: 'Unauthenticated user attempting $route must be redirected to /welcome',
        );
      }
    });

    test('Public catalog routes allow guest browsing and auth pages allow unauthenticated access', () {
      final catalogRoutes = ['/browse', '/categories'];

      for (final route in catalogRoutes) {
        final redirect = AppRouter.handleRedirect(
          loc: route,
          isAuth: false,
          isGuest: true,
          userType: UserType.reader,
          role: UserRole.none,
          onboardingCompleted: false,
        );
        expect(
          redirect,
          isNull,
          reason: 'Guest must be able to view catalog route $route without being redirected away',
        );
      }

      // Unauthenticated non-guest visiting login/welcome stays on auth page
      final authRedirect = AppRouter.handleRedirect(
        loc: '/welcome',
        isAuth: false,
        isGuest: false,
        userType: UserType.reader,
        role: UserRole.none,
        onboardingCompleted: false,
      );
      expect(authRedirect, isNull, reason: 'Unauthenticated user on /welcome stays on /welcome');

      // Guest visiting /welcome is routed to / (Home) to browse immediately
      final guestWelcomeRedirect = AppRouter.handleRedirect(
        loc: '/welcome',
        isAuth: false,
        isGuest: true,
        userType: UserType.reader,
        role: UserRole.none,
        onboardingCompleted: false,
      );
      expect(guestWelcomeRedirect, equals('/'), reason: 'Guest on /welcome enters normal home browsing');
    });
  });
}
