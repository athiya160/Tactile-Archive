import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../features/cart/presentation/bloc/cart_state.dart';
import '../design_system/tokens/ds_colors.dart';
import '../design_system/tokens/ds_radius.dart';

class DashboardLayout extends StatefulWidget {
  final Widget child;
  final String activeTab;

  const DashboardLayout({
    super.key,
    required this.child,
    required this.activeTab,
  });

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  bool _mobileMenuOpen = false;
  String _searchQuery = '';

  void _navigate(BuildContext context, String tab) {
    setState(() => _mobileMenuOpen = false);
    switch (tab) {
      case 'catalog':
        context.go('/browse');
        break;
      case 'favorites':
        context.go('/favorites');
        break;
      case 'cart':
        context.go('/cart');
        break;
      case 'library':
        context.go('/library');
        break;
      case 'about':
        context.go('/about');
        break;
      case 'contact':
        context.go('/contact');
        break;
      case 'terms':
        context.go('/terms-and-conditions');
        break;
      case 'privacy':
        context.go('/privacy-policy');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 1024;

    if (isDesktop) {
      final showSidebar = [
        'profile',
        'favorites',
        'library',
        'orders',
        'settings',
      ].contains(widget.activeTab);

      if (!showSidebar) {
        return widget.child;
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSidebar(context),
          Expanded(child: widget.child),
        ],
      );
    }

    return Scaffold(
      backgroundColor: DSColors.warmIvory,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(context, isDesktop),
              if (!isDesktop) _buildMobileSearch(),
              Expanded(
                child: widget.child,
              ),
            ],
          ),
          if (_mobileMenuOpen) _buildMobileDrawer(context),
          if (!isDesktop) _buildMobileBottomNav(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        border: const Border(bottom: BorderSide(color: Color(0x1A061B0E))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: DSColors.warmGold,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DSColors.softBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const FaIcon(
                  FontAwesomeIcons.book,
                  size: 18,
                  color: Color(0xFF061B0E),
                ),
              ),
              const SizedBox(width: 10),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _navigate(context, 'catalog'),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'The Tactile Archive',
                        style: TextStyle(
                          color: Color(0xFF061B0E),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: DSColors.warmIvory,
                          border: Border.all(color: DSColors.softBorder),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BETA',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF586159),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (isDesktop)
            Row(
              children: [
                _buildHeaderTextButton(context, 'catalog', 'Home'),
                const SizedBox(width: 24),
                _buildHeaderTextButton(context, 'about', 'About'),
                const SizedBox(width: 24),
                _buildHeaderTextButton(context, 'contact', 'Contact'),
              ],
            ),

          if (isDesktop)
            Container(
              width: 300,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DSColors.softBorder),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.magnifyingGlass,
                    size: 16,
                    color: Color(0xFF586159),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF061B0E),
                        fontFamily: 'Inter',
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search by title, author or category...',
                        hintStyle: TextStyle(
                          color: Color(0x99586159),
                          fontSize: 14,
                          fontFamily: 'Inter',
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              if (isDesktop && widget.activeTab == 'catalog')
                Row(
                  children: [
                    _buildHeaderIconButton(
                      context,
                      'favorites',
                      FontAwesomeIcons.heart,
                      0,
                    ),
                    const SizedBox(width: 16),
                    _buildHeaderIconButton(
                      context,
                      'library',
                      FontAwesomeIcons.bookOpen,
                      0,
                    ),
                    const SizedBox(width: 16),
                    BlocBuilder<CartBloc, CartState>(
                      builder: (context, state) {
                        int count = 0;
                        if (state is CartLoaded) {
                          count = state.cart.items.length;
                        }
                        return _buildHeaderIconButton(
                          context,
                          'cart',
                          FontAwesomeIcons.cartShopping,
                          count,
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                  ],
                ),

              if (isDesktop)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF059669),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'API Live',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF586159),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 16),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                  border: Border.all(color: DSColors.softBorder),
                ),
                alignment: Alignment.center,
                child: const FaIcon(
                  FontAwesomeIcons.user,
                  size: 14,
                  color: Color(0xFF586159),
                ),
              ),
              if (!isDesktop)
                IconButton(
                  tooltip: 'Toggle Navigation Menu',
                  onPressed: () =>
                      setState(() => _mobileMenuOpen = !_mobileMenuOpen),
                  icon: FaIcon(
                    _mobileMenuOpen
                        ? FontAwesomeIcons.xmark
                        : FontAwesomeIcons.bars,
                    size: 20,
                    color: DSColors.charcoal,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTextButton(
    BuildContext context,
    String tab,
    String label,
  ) {
    final isActive = widget.activeTab == tab;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _navigate(context, tab),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? DSColors.deepForestGreen : DSColors.charcoal,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton(
    BuildContext context,
    String tab,
    dynamic icon,
    int count,
  ) {
    String tooltipLabel = 'Navigate';
    if (tab == 'favorites') tooltipLabel = 'Saved Books';
    if (tab == 'library') tooltipLabel = 'My Library';
    if (tab == 'cart') tooltipLabel = 'Shopping Cart';

    return Tooltip(
      message: tooltipLabel,
      child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _navigate(context, tab),
        child: Row(
          children: [
            FaIcon(icon, size: 18, color: DSColors.charcoal),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF061B0E),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ));
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 256,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DSColors.softBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'NAVIGATION',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF586159),
                      letterSpacing: 2,
                    ),
                  ),
                ),
                _buildSidebarItem(
                  context,
                  'catalog',
                  'All Catalog',
                  FontAwesomeIcons.layerGroup,
                  0,
                ),
                _buildSidebarItem(
                  context,
                  'favorites',
                  'Favorites',
                  FontAwesomeIcons.solidHeart,
                  0,
                ),
                BlocBuilder<CartBloc, CartState>(
                  builder: (context, state) {
                    int count = 0;
                    if (state is CartLoaded) count = state.cart.items.length;
                    return _buildSidebarItem(
                      context,
                      'cart',
                      'Cart Drawer',
                      FontAwesomeIcons.cartShopping,
                      count,
                    );
                  },
                ),
                _buildSidebarItem(
                  context,
                  'library',
                  'My Library',
                  FontAwesomeIcons.bookOpen,
                  0,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DSColors.softBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'CATEGORIES',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF586159),
                      letterSpacing: 2,
                    ),
                  ),
                ),
                _buildCategoryItem(context, 'All Categories'),
                _buildCategoryItem(context, 'Fiction'),
                _buildCategoryItem(context, 'Textbooks'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    String tab,
    String label,
    dynamic icon,
    int count,
  ) {
    final isActive = widget.activeTab == tab;
    return InkWell(
      onTap: () => _navigate(context, tab),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? DSColors.warmGold.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
            color: isActive ? DSColors.warmGold : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                FaIcon(
                  icon,
                  size: 14,
                  color: isActive
                      ? DSColors.deepForestGreen
                      : DSColors.charcoal,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? DSColors.deepForestGreen
                        : DSColors.charcoal,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: DSColors.softBorder,
                  borderRadius: BorderRadius.circular(DSRadius.sm),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF061B0E),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, String label) {
    return InkWell(
      onTap: () => context.go('/browse?category=${Uri.encodeComponent(label)}'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF586159),
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DSColors.softBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const FaIcon(
              FontAwesomeIcons.magnifyingGlass,
              size: 16,
              color: Color(0xFF586159),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                onSubmitted: (v) {
                  if (_searchQuery.trim().isNotEmpty) {
                    context.go('/browse?search=${Uri.encodeComponent(_searchQuery.trim())}');
                  }
                },
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF061B0E),
                  fontFamily: 'Inter',
                ),
                decoration: const InputDecoration(
                  hintText: 'Search books...',
                  hintStyle: TextStyle(
                    color: Color(0xFF586159),
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        alignment: Alignment.centerRight,
        child: Container(
          width: 288,
          color: Colors.white,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'The Tactile Archive',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF061B0E),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close Menu',
                      onPressed: () => setState(() => _mobileMenuOpen = false),
                      icon: const FaIcon(
                        FontAwesomeIcons.xmark,
                        size: 20,
                        color: Color(0xFF586159),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _buildSidebarItem(context, 'catalog', 'All Catalog', FontAwesomeIcons.layerGroup, 0),
                    _buildSidebarItem(context, 'favorites', 'Favorites', FontAwesomeIcons.solidHeart, 0),
                    _buildSidebarItem(context, 'cart', 'Cart Drawer', FontAwesomeIcons.cartShopping, 0),
                    _buildSidebarItem(context, 'library', 'My Library', FontAwesomeIcons.bookOpen, 0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBottomNav(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMobileNavItem(
              context,
              'catalog',
              'Catalog',
              FontAwesomeIcons.layerGroup,
            ),
            _buildMobileNavItem(
              context,
              'favorites',
              'Favorites',
              FontAwesomeIcons.solidHeart,
            ),
            _buildMobileNavItem(
              context,
              'cart',
              'Cart',
              FontAwesomeIcons.cartShopping,
            ),
            _buildMobileNavItem(
              context,
              'library',
              'Library',
              FontAwesomeIcons.bookOpen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNavItem(
    BuildContext context,
    String tab,
    String label,
    dynamic icon,
  ) {
    final isActive = widget.activeTab == tab;
    return InkWell(
      onTap: () => _navigate(context, tab),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              size: 16,
              color: isActive
                  ? DSColors.deepForestGreen
                  : DSColors.charcoal,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? DSColors.deepForestGreen
                    : DSColors.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
