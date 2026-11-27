import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'desktop_top_nav_bar.dart';
import 'mobile_top_nav_bar.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class MainShellScaffold extends StatelessWidget {
  final Widget child;

  const MainShellScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        final location = GoRouterState.of(context).uri.path;
        final showMobileTopBar = !isDesktop && location != '/profile' && !location.startsWith('/provider');

        return Scaffold(
          backgroundColor: DSColors.background,
          drawer: isDesktop ? null : const TactileMobileDrawer(),
          body: Column(
            children: [
              if (isDesktop)
                const DesktopTopNavBar()
              else if (showMobileTopBar)
                const MobileTopNavBar(),
              Expanded(
                child: child,
              ),
            ],
          ),
        );
      },
    );
  }
}
