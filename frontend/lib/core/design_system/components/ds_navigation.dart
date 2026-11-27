import 'package:flutter/material.dart';
import '../tokens/ds_colors.dart';
import '../tokens/ds_shadows.dart';

class DSNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget logo;
  final List<Widget> navLinks;
  final Widget? centerWidget;
  final Widget? trailing;

  const DSNavigationBar({
    super.key,
    required this.logo,
    required this.navLinks,
    this.centerWidget,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DSColors.surface,
        boxShadow: DSShadows.sm,
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: SizedBox(
                height: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    logo,
                    if (MediaQuery.of(context).size.width > 768)
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            ...navLinks,
                            if (centerWidget != null) ...[
                              const SizedBox(width: 24),
                              Expanded(child: centerWidget!),
                            ] else
                              const Spacer(),
                            if (trailing != null) ...[
                              const SizedBox(width: 24),
                              trailing!,
                            ],
                          ],
                        ),
                      ),
                    if (MediaQuery.of(context).size.width <= 768)
                      IconButton(
                        icon: const Icon(Icons.menu, color: DSColors.primary),
                        onPressed: () => Scaffold.of(context).openEndDrawer(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}

class DSDrawer extends StatelessWidget {
  final Widget logo;
  final List<Widget> navLinks;
  final Widget? trailing;

  const DSDrawer({
    super.key,
    required this.logo,
    required this.navLinks,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: DSColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(padding: const EdgeInsets.all(24.0), child: logo),
            const Divider(color: DSColors.borderLight),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: navLinks.map((link) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: link,
                  );
                }).toList(),
              ),
            ),
            if (trailing != null)
              Padding(padding: const EdgeInsets.all(24.0), child: trailing!),
          ],
        ),
      ),
    );
  }
}

class DSBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;

  const DSBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(boxShadow: DSShadows.lg),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: items,
        backgroundColor: DSColors.surface,
        selectedItemColor: DSColors.secondary,
        unselectedItemColor: DSColors.textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
