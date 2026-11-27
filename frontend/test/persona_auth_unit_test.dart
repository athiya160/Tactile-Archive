import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:libri_flow/core/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Persona Auth & Session Restoration Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ApiService.token = null;
      ApiService.role = UserRole.none;
      ApiService.userType = UserType.reader;
      ApiService.authState.value = false;
      ApiService.roleState.value = UserRole.none;
      ApiService.userTypeState.value = UserType.reader;
    });

    test('Persona defaults to reader initially', () {
      expect(ApiService.persona, equals(UserType.reader));
      expect(ApiService.userType, equals(UserType.reader));
      expect(ApiService.personaState.value, equals(UserType.reader));
    });

    test('Session restoration: loads student persona from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'mock_jwt_token_123',
        'user_role': 'customer',
        'user_persona': 'student',
        'user_name': 'Student Tester',
        'onboarding_completed': true,
      });

      await ApiService.loadToken();

      expect(ApiService.isLoggedIn, isTrue);
      expect(ApiService.persona, equals(UserType.student));
      expect(ApiService.userType, equals(UserType.student));
      expect(ApiService.personaState.value, equals(UserType.student));
      expect(ApiService.userName, equals('Student Tester'));
    });

    test('Session restoration: loads reader persona from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'mock_jwt_token_456',
        'user_role': 'customer',
        'user_persona': 'reader',
        'user_name': 'Reader Tester',
        'onboarding_completed': true,
      });

      await ApiService.loadToken();

      expect(ApiService.isLoggedIn, isTrue);
      expect(ApiService.persona, equals(UserType.reader));
      expect(ApiService.userType, equals(UserType.reader));
      expect(ApiService.personaState.value, equals(UserType.reader));
      expect(ApiService.userName, equals('Reader Tester'));
    });

    test('Session restoration: falls back to user_type if user_persona key is not present', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'mock_jwt_token_789',
        'user_role': 'customer',
        'user_type': 'student',
        'user_name': 'Fallback Student',
      });

      await ApiService.loadToken();

      expect(ApiService.isLoggedIn, isTrue);
      expect(ApiService.persona, equals(UserType.student));
      expect(ApiService.userType, equals(UserType.student));
    });

    test('Logout clears persona and session data', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'mock_jwt_token_123',
        'user_role': 'customer',
        'user_persona': 'student',
        'user_name': 'Student Tester',
      });

      await ApiService.loadToken();
      expect(ApiService.isLoggedIn, isTrue);

      await ApiService.logout();

      expect(ApiService.isLoggedIn, isFalse);
      expect(ApiService.token, isNull);
      expect(ApiService.persona, equals(UserType.reader));
      expect(ApiService.role, equals(UserRole.none));

      // Verify SharedPreferences is cleared
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
      expect(prefs.getString('user_persona'), isNull);
      expect(prefs.getString('user_type'), isNull);
    });

    test('Student Onboarding: saveStudentProfile persists degree, semester, year, and college in session', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'mock_jwt_token_student',
        'user_role': 'customer',
        'user_persona': 'student',
      });
      await ApiService.loadToken();

      final success = await ApiService.saveStudentProfile(
        educationLevel: '2nd Year',
        course: 'Computer Science & Engineering',
        examGoal: 'Semester 3',
        college: 'Oxford University',
        semester: 'Semester 3',
        academicYear: '2nd Year',
      );

      expect(success, isTrue);
      expect(ApiService.onboardingCompleted, isTrue);
      expect(ApiService.persona, equals(UserType.student));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('student_degree'), equals('Computer Science & Engineering'));
      expect(prefs.getString('student_semester'), equals('Semester 3'));
      expect(prefs.getString('student_academic_year'), equals('2nd Year'));
      expect(prefs.getString('student_college'), equals('Oxford University'));
      expect(prefs.getBool('onboarding_completed'), isTrue);
    });
  });

  group('Phase 14G: Persona-Aware Routing Unit Tests', () {
    test('1. Reader login: redirects to Reader dashboard on /reader', () {
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
    });

    test('2. Student login (incomplete onboarding): redirects to student onboarding', () {
      // From login page
      final fromLogin = AppRouter.handleRedirect(
        loc: '/login',
        isAuth: true,
        isGuest: false,
        userType: UserType.student,
        role: UserRole.customer,
        onboardingCompleted: false,
      );
      expect(fromLogin, equals('/onboarding/student-preferences'));

      // Landing on root /
      final onRoot = AppRouter.handleRedirect(
        loc: '/',
        isAuth: true,
        isGuest: false,
        userType: UserType.student,
        role: UserRole.customer,
        onboardingCompleted: false,
      );
      expect(onRoot, equals('/onboarding/student-preferences'));

      // Attempting /student directly before onboarding completed
      final onStudentDirect = AppRouter.handleRedirect(
        loc: '/student',
        isAuth: true,
        isGuest: false,
        userType: UserType.student,
        role: UserRole.customer,
        onboardingCompleted: false,
      );
      expect(onStudentDirect, equals('/onboarding/student-preferences'));

      // Staying on /onboarding/student-preferences
      final onOnboarding = AppRouter.handleRedirect(
        loc: '/onboarding/student-preferences',
        isAuth: true,
        isGuest: false,
        userType: UserType.student,
        role: UserRole.customer,
        onboardingCompleted: false,
      );
      expect(onOnboarding, isNull, reason: 'Allowed to stay on student onboarding page');
    });

    test('3. Student login (completed onboarding): redirects to /student dashboard', () {
      // From login page
      final fromLogin = AppRouter.handleRedirect(
        loc: '/login',
        isAuth: true,
        isGuest: false,
        userType: UserType.student,
        role: UserRole.customer,
        onboardingCompleted: true,
      );
      expect(fromLogin, equals('/student'));

      // Landing on root /
      final onRoot = AppRouter.handleRedirect(
        loc: '/',
        isAuth: true,
        isGuest: false,
        userType: UserType.student,
        role: UserRole.customer,
        onboardingCompleted: true,
      );
      expect(onRoot, equals('/student'));

      // On /student dashboard
      final onStudent = AppRouter.handleRedirect(
        loc: '/student',
        isAuth: true,
        isGuest: false,
        userType: UserType.student,
        role: UserRole.customer,
        onboardingCompleted: true,
      );
      expect(onStudent, isNull, reason: 'Authenticated student with completed onboarding stays on /student');
    });

    test('4. Provider access: preserves Provider Hub functionality', () {
      // Authenticated Provider from login page
      final fromLogin = AppRouter.handleRedirect(
        loc: '/login',
        isAuth: true,
        isGuest: false,
        userType: UserType.reader,
        role: UserRole.provider,
        onboardingCompleted: true,
      );
      expect(fromLogin, equals('/provider'));

      // Authenticated Provider landing on root /
      final onRoot = AppRouter.handleRedirect(
        loc: '/',
        isAuth: true,
        isGuest: false,
        userType: UserType.reader,
        role: UserRole.provider,
        onboardingCompleted: true,
      );
      expect(onRoot, equals('/provider'));

      // Authenticated Provider on /provider
      final onProvider = AppRouter.handleRedirect(
        loc: '/provider',
        isAuth: true,
        isGuest: false,
        userType: UserType.reader,
        role: UserRole.provider,
        onboardingCompleted: true,
      );
      expect(onProvider, isNull, reason: 'Provider stays on /provider');

      // Unauthenticated non-guest attempting /provider
      final unauthAttempt = AppRouter.handleRedirect(
        loc: '/provider',
        isAuth: false,
        isGuest: false,
        userType: UserType.reader,
        role: UserRole.none,
        onboardingCompleted: false,
      );
      expect(unauthAttempt, equals('/welcome'), reason: 'Unauthenticated user redirected away from /provider');
    });

    test('5. Logout: redirects unauthenticated users to /welcome', () {
      // Unauthenticated user attempting protected routes
      expect(
        AppRouter.handleRedirect(
          loc: '/student',
          isAuth: false,
          isGuest: false,
          userType: UserType.reader,
          role: UserRole.none,
          onboardingCompleted: false,
        ),
        equals('/welcome'),
      );

      expect(
        AppRouter.handleRedirect(
          loc: '/orders',
          isAuth: false,
          isGuest: false,
          userType: UserType.reader,
          role: UserRole.none,
          onboardingCompleted: false,
        ),
        equals('/welcome'),
      );

      // Unauthenticated user on root / stays on / to view public HomePage
      expect(
        AppRouter.handleRedirect(
          loc: '/',
          isAuth: false,
          isGuest: false,
          userType: UserType.reader,
          role: UserRole.none,
          onboardingCompleted: false,
        ),
        isNull,
      );

      // User on /welcome stays on /welcome
      expect(
        AppRouter.handleRedirect(
          loc: '/welcome',
          isAuth: false,
          isGuest: false,
          userType: UserType.reader,
          role: UserRole.none,
          onboardingCompleted: false,
        ),
        isNull,
      );
    });

    test('6. Login again: restores session and routes to correct persona destination', () {
      // Re-login as Reader
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
      );

      // Re-login as Student (completed onboarding)
      expect(
        AppRouter.handleRedirect(
          loc: '/login',
          isAuth: true,
          isGuest: false,
          userType: UserType.student,
          role: UserRole.customer,
          onboardingCompleted: true,
        ),
        equals('/student'),
      );

      // Re-login as Provider
      expect(
        AppRouter.handleRedirect(
          loc: '/login',
          isAuth: true,
          isGuest: false,
          userType: UserType.reader,
          role: UserRole.provider,
          onboardingCompleted: true,
        ),
        equals('/provider'),
      );
    });

    test('7. Direct navigation to /student and /profile is preserved', () {
      // Direct navigation to /student for authenticated student
      final studentToStudent = AppRouter.handleRedirect(
        loc: '/student',
        isAuth: true,
        isGuest: false,
        userType: UserType.student,
        role: UserRole.customer,
        onboardingCompleted: true,
      );
      expect(studentToStudent, isNull);

      // Direct navigation to /student for authenticated reader (can explore without redirect loop)
      final readerToStudent = AppRouter.handleRedirect(
        loc: '/student',
        isAuth: true,
        isGuest: false,
        userType: UserType.reader,
        role: UserRole.customer,
        onboardingCompleted: true,
      );
      expect(readerToStudent, isNull);

      // Direct navigation to /profile for any authenticated user
      final toProfile = AppRouter.handleRedirect(
        loc: '/profile',
        isAuth: true,
        isGuest: false,
        userType: UserType.student,
        role: UserRole.customer,
        onboardingCompleted: true,
      );
      expect(toProfile, isNull);

      // Direct navigation to /home, /browse, /categories, /ai-concierge, /sell, /cart, /checkout, /orders
      final explicitRoutes = [
        '/home',
        '/browse',
        '/categories',
        '/ai-concierge',
        '/sell',
        '/cart',
        '/checkout',
        '/orders',
      ];

      for (final route in explicitRoutes) {
        final result = AppRouter.handleRedirect(
          loc: route,
          isAuth: true,
          isGuest: false,
          userType: UserType.student,
          role: UserRole.customer,
          onboardingCompleted: true,
        );
        expect(result, isNull, reason: 'Direct navigation to $route must return null (preserved)');
      }
    });

    test('Safety: Reader is never forced through student onboarding', () {
      final readerAccidentallyOnOnboarding = AppRouter.handleRedirect(
        loc: '/onboarding/student-preferences',
        isAuth: true,
        isGuest: false,
        userType: UserType.reader,
        role: UserRole.customer,
        onboardingCompleted: false,
      );
      expect(readerAccidentallyOnOnboarding, equals('/reader'));
    });
  });
}
