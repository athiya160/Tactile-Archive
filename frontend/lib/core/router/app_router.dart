import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../di/service_locator.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/browse_books_page.dart';
import '../../features/home/presentation/pages/categories_page.dart';
import '../../features/home/presentation/pages/about_page.dart';
import '../../features/home/presentation/pages/terms_and_conditions_page.dart';
import '../../features/home/presentation/pages/privacy_policy_page.dart';
import '../../features/home/presentation/pages/contact_page.dart';
import '../../features/home/presentation/pages/shipping_policy_page.dart';
import '../../features/book_details/presentation/bloc/book_details_bloc.dart';
import '../../features/book_details/presentation/bloc/book_details_event.dart';
import '../../features/book_details/presentation/pages/book_details_page.dart';
import '../../features/book_details/presentation/pages/review_page.dart';
import '../../features/favorites/presentation/bloc/favorites_bloc.dart';
import '../../features/favorites/presentation/bloc/favorites_event.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/library/presentation/bloc/library_bloc.dart';
import '../../features/library/presentation/bloc/library_event.dart';
import '../../features/library/presentation/pages/library_page.dart';
import '../../features/activity/presentation/bloc/activity_bloc.dart';
import '../../features/activity/presentation/pages/activity_page.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/bloc/profile_event.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/account_settings/presentation/bloc/settings_bloc.dart';
import '../../features/account_settings/presentation/pages/account_settings_page.dart';
import '../../features/order_history/presentation/bloc/orders_bloc.dart';
import '../../features/order_history/presentation/pages/order_history_page.dart';
import '../../features/admin/presentation/pages/admin_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/cart/presentation/pages/checkout_page.dart';
import '../../features/delivery_address/presentation/bloc/address_bloc.dart';
import '../../features/delivery_address/presentation/bloc/address_event.dart';
import '../../features/delivery_address/presentation/pages/delivery_address_page.dart';
import '../../features/support/presentation/bloc/support_bloc.dart';
import '../../features/support/presentation/bloc/support_event.dart';
import '../../features/support/presentation/pages/support_page.dart';
import '../../features/support/presentation/pages/faqs_page.dart';
import '../../features/report_issue/presentation/bloc/report_issue_bloc.dart';
import '../../features/report_issue/presentation/bloc/report_issue_event.dart';
import '../../features/report_issue/presentation/pages/report_issue_page.dart';
import '../../features/feedback/presentation/bloc/feedback_bloc.dart';
import '../../features/feedback/presentation/bloc/feedback_event.dart';
import '../../features/feedback/presentation/pages/feedback_page.dart';
import '../../features/terms/presentation/bloc/terms_bloc.dart';
import '../../features/terms/presentation/bloc/terms_event.dart';
import '../../features/terms/presentation/pages/terms_page.dart';
import '../../features/book_owner_details/presentation/bloc/book_owner_details_bloc.dart';
import '../../features/book_owner_details/presentation/bloc/book_owner_details_event.dart';
import '../../features/book_owner_details/presentation/pages/book_owner_details_page.dart';
import '../../features/add_book/presentation/pages/add_book_page.dart';
import '../../features/provider_portfolio/presentation/bloc/provider_portfolio_bloc.dart';
import '../../features/provider_portfolio/presentation/bloc/provider_portfolio_event.dart';
import '../../features/provider_portfolio/presentation/pages/provider_portfolio_page.dart';
import '../../features/buy_now/presentation/pages/buy_now_checkout_page.dart';
import '../../features/buy_now/presentation/bloc/buy_now_bloc.dart';
import '../../features/home/domain/entities/book.dart';
import '../services/api_service.dart';

import '../../features/auth/presentation/pages/auth_landing_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../widgets/main_shell_scaffold.dart';

import '../../features/auth/presentation/pages/onboarding_persona_page.dart';
import '../../features/personalization/presentation/pages/student_preferences_page.dart';
import '../../features/personalization/presentation/pages/reader_preferences_page.dart';
import '../../features/personalization/presentation/pages/student_study_assistant_page.dart';
import '../../features/personalization/presentation/pages/reader_reading_companion_page.dart';
import '../../features/personalization/presentation/pages/persona_plans_page.dart';
import '../../features/personalization/presentation/pages/shelf_scanner_page.dart';
import '../../features/home/presentation/pages/student_dashboard_page.dart';
import '../../features/home/presentation/pages/reader_dashboard_page.dart';
import '../../features/browse_books/presentation/pages/mood_recommendation_page.dart';
import '../../features/study_plan/presentation/pages/reading_plan_page.dart';
import '../../features/home/presentation/pages/exchange_map_page.dart';
import '../../features/ai/presentation/pages/archive_ai_page.dart';
import '../../features/ai/presentation/pages/ai_reading_concierge_page.dart';
import '../../features/ai/presentation/pages/damage_inspection_screen.dart';
import '../../features/profile/presentation/pages/provider_dashboard_page.dart';
import '../../features/profile/presentation/pages/reader_passport_page.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNavKey');
  static final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shellRouteKey');
  static final _branchHomeNavKey = GlobalKey<NavigatorState>(debugLabel: 'branchHomeKey');
  static final _branchExploreNavKey = GlobalKey<NavigatorState>(debugLabel: 'branchExploreKey');
  static final _branchLibraryNavKey = GlobalKey<NavigatorState>(debugLabel: 'branchLibraryKey');
  static final _branchSavedNavKey = GlobalKey<NavigatorState>(debugLabel: 'branchSavedKey');
  static final _branchProfileNavKey = GlobalKey<NavigatorState>(debugLabel: 'branchProfileKey');

  /// Persona-aware redirect logic evaluated by GoRouter.
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

    // 0. Admin Route Gate — strictly restrict /admin to verified administrators
    if (loc == '/admin' || loc.startsWith('/admin/')) {
      if (!isAuth) {
        return '/welcome';
      }
      if (!ApiService.isAdmin) {
        return '/';
      }
    }

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
  }

  static final router = GoRouter(
    initialLocation: '/',
    navigatorKey: _rootNavigatorKey,
    refreshListenable: Listenable.merge([
      ApiService.authState,
      ApiService.adminState,
      ApiService.roleState,
      ApiService.userTypeState,
      ApiService.onboardingState,
      ApiService.experienceState,
      ApiService.providerState,
    ]),
    redirect: (context, state) => handleRedirect(
      loc: state.matchedLocation,
      isAuth: ApiService.isLoggedIn,
      isGuest: ApiService.isGuest,
      userType: ApiService.userType,
      role: ApiService.role,
      onboardingCompleted: ApiService.onboardingCompleted,
      activeExperience: ApiService.activeExperience,
    ),
    routes: [
      // ── Auth Routes (full-screen, outside shell) ──────────────────────────
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/welcome',
        builder: (context, state) => const AuthLandingPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/login',
        builder: (context, state) {
          final role = state.extra as UserRole? ?? UserRole.customer;
          return LoginPage(role: role);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/register',
        builder: (context, state) {
          if (state.extra is UserRole) {
            return RegisterPage(role: state.extra as UserRole);
          } else if (state.extra is UserType) {
            return RegisterPage(
              role: UserRole.customer,
              persona: state.extra as UserType,
            );
          }
          return const RegisterPage(role: UserRole.customer);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/reset-password',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordPage(token: token);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/onboarding/user-type',
        builder: (context, state) => const OnboardingPersonaPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/student/onboarding',
        builder: (context, state) => const StudentPreferencesPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/onboarding/student-preferences',
        builder: (context, state) => const StudentPreferencesPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/onboarding/reader-preferences',
        builder: (context, state) => const ReaderPreferencesPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/student/study-assistant',
        builder: (context, state) => const StudentStudyAssistantPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/study-assistant',
        builder: (context, state) => const StudentStudyAssistantPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/reader/reading-companion',
        builder: (context, state) => const ReaderReadingCompanionPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/plans',
        builder: (context, state) => const PersonaPlansPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/semester-planner',
        builder: (context, state) => const PersonaPlansPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/reading-plan',
        builder: (context, state) {
          final title = state.uri.queryParameters['title'] ?? 'Whispers of the Ancient Vellum';
          return ReadingPlanPage(bookTitle: title);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/shelf-scanner',
        builder: (context, state) => const ShelfScannerPage(),
      ),

      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/passport',
        builder: (context, state) => const ReaderPassportPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/inspect-damage',
        builder: (context, state) => const DamageInspectionScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/archive-ai',
        builder: (context, state) => const ArchiveAIPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/ai-concierge',
        builder: (context, state) => const AIReadingConciergePage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/provider',
        builder: (context, state) => const ProviderDashboardPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/planner',
        builder: (context, state) => BlocProvider(
          create: (context) => sl<HomeBloc>()..add(HomeStarted()),
          child: const StudentDashboardPage(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/mood-match',
        builder: (context, state) => const MoodRecommendationPage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShellScaffold(child: child),
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return _ScaffoldWithBottomNavBar(
                navigationShell: navigationShell,
              );
            },
            branches: [
              // Branch 0: Home / Study
              StatefulShellBranch(
                navigatorKey: _branchHomeNavKey,
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) => BlocProvider(
                      create: (context) => sl<HomeBloc>()..add(HomeStarted()),
                      child: const HomePage(),
                    ),
                  ),
                  GoRoute(
                    path: '/home',
                    builder: (context, state) => BlocProvider(
                      create: (context) => sl<HomeBloc>()..add(HomeStarted()),
                      child: const HomePage(),
                    ),
                  ),
                  GoRoute(
                    path: '/student',
                    builder: (context, state) => BlocProvider(
                      create: (context) => sl<HomeBloc>()..add(HomeStarted()),
                      child: const StudentDashboardPage(),
                    ),
                  ),
                  GoRoute(
                    path: '/reader',
                    builder: (context, state) => BlocProvider(
                      create: (context) => sl<HomeBloc>()..add(HomeStarted()),
                      child: const ReaderDashboardPage(),
                    ),
                  ),
                  GoRoute(
                    path: '/categories',
                    builder: (context, state) => const CategoriesPage(),
                  ),
                  GoRoute(
                    path: '/about',
                    builder: (context, state) => const AboutPageV2(),
                  ),
                  GoRoute(
                    path: '/contact',
                    builder: (context, state) => const ContactPage(),
                  ),
                  GoRoute(
                    path: '/terms-and-conditions',
                    builder: (context, state) =>
                        const TermsAndConditionsPageV2(),
                  ),
                  GoRoute(
                    path: '/privacy-policy',
                    builder: (context, state) => const PrivacyPolicyPageV2(),
                  ),
                  GoRoute(
                    path: '/shipping-policy',
                    builder: (context, state) => const ShippingPolicyPage(),
                  ),
                ],
              ),
              // Branch 1: Explore (/browse)
              StatefulShellBranch(
                navigatorKey: _branchExploreNavKey,
                routes: [
                  GoRoute(
                    path: '/browse',
                    builder: (context, state) {
                      final category = state.uri.queryParameters['category'];
                      final search = state.uri.queryParameters['search'];
                      final from = state.uri.queryParameters['from'];
                      return BrowseBooksPage(
                        initialCategory: category,
                        initialSearchQuery: search,
                        from: from,
                      );
                    },
                  ),
                  GoRoute(
                    path: '/explore',
                    builder: (context, state) {
                      final category = state.uri.queryParameters['category'];
                      final search = state.uri.queryParameters['search'];
                      final from = state.uri.queryParameters['from'];
                      return BrowseBooksPage(
                        initialCategory: category,
                        initialSearchQuery: search,
                        from: from,
                      );
                    },
                  ),
                ],
              ),
              // Branch 2: Library (/library)
              StatefulShellBranch(
                navigatorKey: _branchLibraryNavKey,
                routes: [
                  GoRoute(
                    path: '/library',
                    builder: (context, state) {
                      final tabStr = state.uri.queryParameters['tab'];
                      final initialTab = tabStr != null
                          ? int.tryParse(tabStr) ?? 0
                          : 0;
                      return BlocProvider(
                        create: (context) => sl<LibraryBloc>()
                          ..add(LibraryStarted(initialTabIndex: initialTab)),
                        child: LibraryPage(initialTabIndex: initialTab),
                      );
                    },
                  ),
                ],
              ),
              // Branch 3: Saved (/favorites, /saved, /exchange-map)
              StatefulShellBranch(
                navigatorKey: _branchSavedNavKey,
                routes: [
                  GoRoute(
                    path: '/favorites',
                    builder: (context, state) => BlocProvider(
                      create: (context) =>
                          sl<FavoritesBloc>()..add(FavoritesStarted()),
                      child: const FavoritesPage(),
                    ),
                  ),
                  GoRoute(
                    path: '/saved',
                    builder: (context, state) => BlocProvider(
                      create: (context) =>
                          sl<FavoritesBloc>()..add(FavoritesStarted()),
                      child: const FavoritesPage(),
                    ),
                  ),
                  GoRoute(
                    path: '/exchange-map',
                    builder: (context, state) => const ExchangeMapPage(),
                  ),
                ],
              ),
              // Branch 4: Account (/profile, /account, /activity)
              StatefulShellBranch(
                navigatorKey: _branchProfileNavKey,
                routes: [
                  GoRoute(
                    path: '/profile',
                    builder: (context, state) => BlocProvider(
                      create: (context) =>
                          sl<ProfileBloc>()..add(ProfileStarted()),
                      child: const ProfilePage(),
                    ),
                  ),
                  GoRoute(
                    path: '/account',
                    builder: (context, state) => BlocProvider(
                      create: (context) =>
                          sl<ProfileBloc>()..add(ProfileStarted()),
                      child: const ProfilePage(),
                    ),
                  ),
                  GoRoute(
                    path: '/activity',
                    builder: (context, state) => BlocProvider(
                      create: (context) =>
                          sl<ActivityBloc>()..add(ActivityStarted()),
                      child: const ActivityPage(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
          GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
            path: '/book/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? 'unknown';
              return BlocProvider(
                create: (context) =>
                    sl<BookDetailsBloc>()..add(BookDetailsStarted(id)),
                child: const BookDetailsPage(),
              );
            },
          ),
          GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
            path: '/book/:id/owner',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? 'unknown';
              return BlocProvider(
                create: (context) =>
                    sl<BookOwnerDetailsBloc>()
                      ..add(BookOwnerDetailsStarted(id)),
                child: const BookOwnerDetailsPage(),
              );
            },
          ),
          GoRoute(
        parentNavigatorKey: _rootNavigatorKey,path: '/cart', builder: (context, state) => const CartPage()),
          GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
            path: '/checkout',
            builder: (context, state) => const CheckoutPage(),
          ),
          GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
            path: '/delivery-address',
            builder: (context, state) {
              final onConfirm = state.extra as VoidCallback?;
              return BlocProvider(
                create: (context) => sl<AddressBloc>()..add(AddressStarted()),
                child: DeliveryAddressPage(onConfirm: onConfirm),
              );
            },
          ),

          GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
            path: '/buy-now-checkout',
            pageBuilder: (context, state) {
              Book? book;
              String mode = 'purchase';
              int? rentalDays;
              double? rentalFee;

              if (state.extra is Book) {
                book = state.extra as Book;
                mode = 'purchase';
              } else if (state.extra is Map<String, dynamic>) {
                final args = state.extra as Map<String, dynamic>;
                book = args['book'] as Book?;
                mode = args['mode'] as String? ?? 'purchase';
                rentalDays = args['rentalDays'] as int?;
                rentalFee = args['rentalFee'] as double?;
              }

              return MaterialPage(
                key: state.pageKey,
                child: BlocProvider(
                  create: (context) => sl<BuyNowBloc>(),
                  child: BuyNowCheckoutPage(
                    book: book,
                    mode: mode,
                    rentalDays: rentalDays,
                    rentalFee: rentalFee,
                  ),
                ),
              );
            },
          ),
          GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
            path: '/report-issue',
            builder: (context, state) => BlocProvider(
              create: (context) =>
                  sl<ReportIssueBloc>()..add(ReportIssueStarted()),
              child: const ReportIssuePage(),
            ),
          ),
          GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
            path: '/account-settings',
            builder: (context, state) => BlocProvider(
              create: (context) => sl<SettingsBloc>()..add(SettingsStarted()),
              child: const AccountSettingsPage(),
            ),
          ),
          GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
            path: '/order-history',
            builder: (context, state) => BlocProvider(
              create: (context) => sl<OrdersBloc>()..add(OrdersStarted()),
              child: const OrderHistoryPage(),
            ),
          ),
          GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
            path: '/orders',
            builder: (context, state) => BlocProvider(
              create: (context) => sl<OrdersBloc>()..add(OrdersStarted()),
              child: const OrderHistoryPage(),
            ),
          ),
          GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
            path: '/review',
            builder: (context, state) {
              final args = state.extra as Map<String, dynamic>;
              final book = args['book'] as Book;
              final orderId = args['orderId'] as String;
              return ReviewPage(book: book, orderId: orderId);
            },
          ),
          GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
            path: '/admin',
            builder: (context, state) => const AdminPage(),
          ),
          GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
            path: '/notifications',
            builder: (context, state) => const NotificationsPage(),
          ),

          GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
            path: '/feedback',
            builder: (context, state) => BlocProvider(
              create: (context) => sl<FeedbackBloc>()..add(FeedbackStarted()),
              child: const FeedbackPage(),
            ),
          ),

          GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
            path: '/terms-conditions',
            builder: (context, state) => BlocProvider(
              create: (context) => sl<TermsBloc>()..add(TermsStarted()),
              child: const TermsPage(),
            ),
          ),
          GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
            path: '/help-support',
            builder: (context, state) => BlocProvider(
              create: (context) => sl<SupportBloc>()..add(SupportStarted()),
              child: const SupportPage(),
            ),
          ),
          GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
            path: '/support',
            builder: (context, state) => BlocProvider(
              create: (context) => sl<SupportBloc>()..add(SupportStarted()),
              child: const SupportPage(),
            ),
          ),
          GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
            path: '/faqs',
            builder: (context, state) => BlocProvider(
              create: (context) => sl<SupportBloc>()..add(SupportStarted()),
              child: const FaqsPage(),
            ),
          ),
          GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
            path: '/add-book',
            builder: (context, state) => const AddBookPage(),
          ),
          GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
            path: '/sell',
            builder: (context, state) => const AddBookPage(),
          ),
          GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
            path: '/provider-portfolio',
            builder: (context, state) => BlocProvider(
              create: (context) =>
                  sl<ProviderPortfolioBloc>()..add(ProviderPortfolioStarted()),
              child: const ProviderPortfolioPage(),
            ),
          ),
    ],
  );
}

class _ScaffoldWithBottomNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _ScaffoldWithBottomNavBar({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;

        if (isDesktop) {
          return navigationShell;
        }

        return ValueListenableBuilder<UserType>(
          valueListenable: ApiService.experienceState,
          builder: (context, activeExperience, _) {
            final isStudent = activeExperience == UserType.student;

            return Column(
              children: [
                Expanded(child: navigationShell),
                _TactileBottomNavBar(
                  navigationShell: navigationShell,
                  isStudent: isStudent,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TactileBottomNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final bool isStudent;

  const _TactileBottomNavBar({
    required this.navigationShell,
    required this.isStudent,
  });

  @override
  Widget build(BuildContext context) {
    final activeIndex = navigationShell.currentIndex;

    final items = [
      _NavItemData(
        label: 'Home',
        icon: isStudent ? Icons.school_outlined : Icons.home_outlined,
        activeIcon: isStudent ? Icons.school_rounded : Icons.home_rounded,
      ),
      const _NavItemData(
        label: 'Explore',
        icon: Icons.explore_outlined,
        activeIcon: Icons.explore_rounded,
      ),
      _NavItemData(
        label: isStudent ? 'Study' : 'Bookshelf',
        icon: isStudent ? Icons.menu_book_outlined : Icons.auto_stories_outlined,
        activeIcon: isStudent ? Icons.menu_book_rounded : Icons.auto_stories_rounded,
      ),
      const _NavItemData(
        label: 'Saved',
        icon: Icons.bookmark_outline_rounded,
        activeIcon: Icons.bookmark_rounded,
      ),
      const _NavItemData(
        label: 'Profile',
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: DSColors.paperWhite,
        border: const Border(
          top: BorderSide(
            color: DSColors.softBorder,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: DSColors.charcoal.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = activeIndex == index;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => navigationShell.goBranch(
                      index,
                      initialLocation: true,
                    ),
                    splashColor: DSColors.deepForestGreen.withValues(alpha: 0.08),
                    highlightColor: Colors.transparent,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              padding: EdgeInsets.symmetric(
                                horizontal: isSelected ? 14 : 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? DSColors.deepForestGreen.withValues(alpha: 0.10)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                isSelected ? item.activeIcon : item.icon,
                                size: 21,
                                color: isSelected
                                    ? DSColors.deepForestGreen
                                    : DSColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                letterSpacing: 0.1,
                                color: isSelected
                                    ? DSColors.charcoal
                                    : DSColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
