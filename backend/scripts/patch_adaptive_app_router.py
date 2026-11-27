import os

path = r'frontend/lib/core/router/app_router.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update refreshListenable
old_refresh = """    refreshListenable: Listenable.merge([
      ApiService.authState,
      ApiService.roleState,
      ApiService.userTypeState,
      ApiService.onboardingState,
    ]),"""

new_refresh = """    refreshListenable: Listenable.merge([
      ApiService.authState,
      ApiService.roleState,
      ApiService.userTypeState,
      ApiService.onboardingState,
      ApiService.experienceState,
      ApiService.providerState,
    ]),"""

assert old_refresh in content, "old_refresh not found"
content = content.replace(old_refresh, new_refresh)

# 2. Update handleRedirect for adaptive activeExperience
old_auth_redirect = """    // 4. Authenticated user landing on auth pages (e.g. /login, /register, /welcome)
    if (onAuthPage && isAuth) {
      if (role == UserRole.provider) {
        return '/provider';
      }
      if (userType == UserType.student) {
        return onboardingCompleted ? '/student' : '/onboarding/student-preferences';
      }
      return '/';
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
        if (userType == UserType.student) {
          return onboardingCompleted ? '/student' : '/onboarding/student-preferences';
        }
        // Authenticated Reader -> normal Home/Browse experience on '/'
        return null;
      }
      // Unauthenticated visitor / Guest on '/' -> normal public Home/Browse experience on '/'
      return null;
    }"""

new_auth_redirect = """    // 4. Authenticated user landing on auth pages (e.g. /login, /register, /welcome)
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
    }"""

assert old_auth_redirect in content, "old_auth_redirect not found"
content = content.replace(old_auth_redirect, new_auth_redirect)

# 3. Update _ScaffoldWithBottomNavBar to listen to experienceState and show adaptive tabs
old_scaffold = """        final isStudent = ApiService.userType == UserType.student;

        return Column(
          children: [
            Expanded(child: navigationShell),
            SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.outlineVariant.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: BottomNavigationBar(
                  currentIndex: navigationShell.currentIndex,
                  onTap: (index) => navigationShell.goBranch(
                    index,
                    initialLocation: true,
                  ),
                  type: BottomNavigationBarType.fixed,
                  elevation: 0,
                  backgroundColor: Colors.white,
                  selectedItemColor: const Color(0xFF0D3B2E),
                  unselectedItemColor: const Color(0xFF718096),
                  selectedLabelStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                  items: [
                    BottomNavigationBarItem(
                      icon: Icon(isStudent
                          ? (navigationShell.currentIndex == 0 ? Icons.school : Icons.school_outlined)
                          : (navigationShell.currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined)),
                      label: isStudent ? 'STUDY' : 'HOME',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(navigationShell.currentIndex == 1 ? Icons.explore_rounded : Icons.explore_outlined),
                      label: 'EXPLORE',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(navigationShell.currentIndex == 2 ? Icons.auto_stories_rounded : Icons.auto_stories_outlined),
                      label: 'LIBRARY',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(navigationShell.currentIndex == 3 ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded),
                      label: 'SAVED',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(navigationShell.currentIndex == 4 ? Icons.person_rounded : Icons.person_outline_rounded),
                      label: 'ACCOUNT',
                    ),
                  ],
                ),
              ),
            ),
          ],
        );"""

new_scaffold = """        return ValueListenableBuilder<UserType>(
          valueListenable: ApiService.experienceState,
          builder: (context, activeExperience, _) {
            final isStudent = activeExperience == UserType.student;

            return Column(
              children: [
                Expanded(child: navigationShell),
                SafeArea(
                  top: false,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: AppColors.outlineVariant.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: BottomNavigationBar(
                      currentIndex: navigationShell.currentIndex,
                      onTap: (index) => navigationShell.goBranch(
                        index,
                        initialLocation: true,
                      ),
                      type: BottomNavigationBarType.fixed,
                      elevation: 0,
                      backgroundColor: Colors.white,
                      selectedItemColor: const Color(0xFF0D3B2E),
                      unselectedItemColor: const Color(0xFF718096),
                      selectedLabelStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      items: [
                        BottomNavigationBarItem(
                          icon: Icon(isStudent
                              ? (navigationShell.currentIndex == 0 ? Icons.school : Icons.school_outlined)
                              : (navigationShell.currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined)),
                          label: isStudent ? 'STUDY' : 'READING',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(navigationShell.currentIndex == 1 ? Icons.explore_rounded : Icons.explore_outlined),
                          label: 'EXPLORE',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(isStudent
                              ? (navigationShell.currentIndex == 2 ? Icons.assignment_rounded : Icons.assignment_outlined)
                              : (navigationShell.currentIndex == 2 ? Icons.auto_stories_rounded : Icons.auto_stories_outlined)),
                          label: isStudent ? 'PLANNER' : 'BOOKSHELF',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(navigationShell.currentIndex == 3 ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded),
                          label: 'SAVED',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(navigationShell.currentIndex == 4 ? Icons.person_rounded : Icons.person_outline_rounded),
                          label: 'ACCOUNT',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );"""

assert old_scaffold in content, "old_scaffold not found"
content = content.replace(old_scaffold, new_scaffold)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("SUCCESSFULLY PATCHED app_router.dart!")
