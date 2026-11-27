import 'package:flutter/material.dart';
import '../router/app_router.dart';
import 'floating_chatbot.dart';

/// Application-level overlay that renders a globally accessible, responsive,
/// floating AI chatbot fixed to the viewport across customer, book-detail,
/// provider, and admin routes.
///
/// It suppresses the launcher on payment/checkout and authentication routes,
/// remains strictly fixed in the viewport during vertical page scrolling,
/// and prevents duplicate chatbot instances across shell and nested routes.
class GlobalChatbotOverlay extends StatefulWidget {
  final Widget? child;

  const GlobalChatbotOverlay({super.key, this.child});

  /// Extracts the current matched URI path safely from GoRouter.
  static String getCurrentPath() {
    try {
      final loc = AppRouter.router.routerDelegate.currentConfiguration.uri.path;
      if (loc.isNotEmpty) return loc;
    } catch (_) {}
    try {
      final loc = AppRouter.router.routeInformationProvider.value.uri.path;
      if (loc.isNotEmpty) return loc;
    } catch (_) {}
    return '/';
  }

  /// Evaluates whether the floating chatbot launcher should be visible.
  /// Suppressed on auth and checkout routes.
  static bool shouldShowChatbot(String path) {
    if (path.isEmpty) return true;
    final normalized = path.endsWith('/') && path.length > 1
        ? path.substring(0, path.length - 1)
        : path;

    const excludedExact = {
      '/login',
      '/register',
      '/forgot-password',
      '/reset-password',
      '/welcome',
      '/checkout',
      '/buy-now-checkout',
      '/delivery-address',
      '/archive-ai',
      '/onboarding/user-type',
    };

    if (excludedExact.contains(normalized)) {
      return false;
    }

    if (normalized.startsWith('/checkout') ||
        normalized.startsWith('/buy-now-checkout') ||
        normalized.startsWith('/delivery-address') ||
        normalized.startsWith('/login') ||
        normalized.startsWith('/register') ||
        normalized.startsWith('/onboarding/user-type')) {
      return false;
    }

    return true;
  }

  /// Determines whether the current route belongs to the indexed shell navigation
  /// which contains the bottom navigation bar on mobile (~70px height).
  static bool isShellRoute(String path) {
    final normalized = path.endsWith('/') && path.length > 1
        ? path.substring(0, path.length - 1)
        : path;
    return normalized == '/' ||
        normalized == '/home' ||
        normalized == '/browse' ||
        normalized == '/library' ||
        normalized == '/favorites' ||
        normalized == '/profile';
  }

  @override
  State<GlobalChatbotOverlay> createState() => _GlobalChatbotOverlayState();
}

class _GlobalChatbotOverlayState extends State<GlobalChatbotOverlay> {
  bool _isChatOpen = false;

  void _handleToggle(bool open) {
    if (_isChatOpen != open) {
      setState(() {
        _isChatOpen = open;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppRouter.router.routerDelegate,
      builder: (context, _) {
        final currentPath = GlobalChatbotOverlay.getCurrentPath();
        final showChatbot = GlobalChatbotOverlay.shouldShowChatbot(currentPath);

        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        final isDesktop = screenWidth >= 700;
        final isShell = GlobalChatbotOverlay.isShellRoute(currentPath);
        final paddingBottom = mediaQuery.padding.bottom;
        final keyboardHeight = mediaQuery.viewInsets.bottom;

        // On mobile, if on a shell route, elevate 84px to clear the bottom navigation bar.
        // On non-shell routes (like /book/:id, /provider, /admin), elevate 24px + safe area.
        // When open, position neatly above the bottom edge and keyboard.
        final bottomOffset = isDesktop
            ? 24.0
            : (_isChatOpen
                ? (8.0 + keyboardHeight)
                : (isShell ? (84.0 + paddingBottom) : (24.0 + paddingBottom)));
        final rightOffset = isDesktop ? 24.0 : (_isChatOpen ? 12.0 : 16.0);
        final leftOffset = isDesktop ? null : (_isChatOpen ? 12.0 : null);

        return Stack(
          children: [
            if (widget.child != null) widget.child!,
            if (showChatbot)
              Positioned(
                key: const ValueKey('global_floating_chatbot_positioned'),
                left: leftOffset,
                right: rightOffset,
                bottom: bottomOffset,
                child: FloatingChatbot(
                  key: const ValueKey('global_floating_chatbot'),
                  currentRoute: currentPath,
                  isOpen: _isChatOpen,
                  onToggle: _handleToggle,
                ),
              ),
          ],
        );
      },
    );
  }
}
