import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../features/cart/presentation/bloc/cart_state.dart';
import '../services/api_service.dart';
import '../tokens/app_tokens.dart';
import 'package:libri_flow/core/design_system/tokens/ds_colors.dart';
import 'package:libri_flow/core/design_system/tokens/ds_radius.dart';

class DesktopTopNavBar extends StatefulWidget {
  const DesktopTopNavBar({super.key});

  @override
  State<DesktopTopNavBar> createState() => _DesktopTopNavBarState();
}

class _DesktopTopNavBarState extends State<DesktopTopNavBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _searchLayerLink = LayerLink();
  OverlayEntry? _searchOverlayEntry;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  void _onSearchFocusChanged() {
    if (_searchFocusNode.hasFocus) {
      _showSearchOverlay();
    } else {
      _hideSearchOverlay();
    }
  }

  void _showSearchOverlay() {
    if (_searchOverlayEntry != null) return;
    final overlayState = Overlay.of(context);
    _searchOverlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 360,
          child: CompositedTransformFollower(
            link: _searchLayerLink,
            offset: const Offset(0, 48), // Height of search bar + 8px gap
            showWhenUnlinked: false,
            child: Material(
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DSRadius.card),
              clipBehavior: Clip.antiAlias,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        'Recent Searches',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    _buildSearchSuggestion('Flutter Development'),
                    _buildSearchSuggestion('Atomic Habits'),
                    _buildSearchSuggestion('Science Fiction'),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Divider(height: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        'Suggestions',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    _buildSearchSuggestion('Best Sellers 2026'),
                    _buildSearchSuggestion('Award-winning Novels'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    overlayState.insert(_searchOverlayEntry!);
  }

  Widget _buildSearchSuggestion(String text) {
    return InkWell(
      onTap: () {
        _searchController.text = text;
        _searchFocusNode.unfocus();
        context.go('/browse?search=${Uri.encodeComponent(text)}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            const FaIcon(
              FontAwesomeIcons.clockRotateLeft,
              size: 14,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _hideSearchOverlay() {
    _searchOverlayEntry?.remove();
    _searchOverlayEntry = null;
  }

  @override
  void dispose() {
    _hideSearchOverlay();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Container(
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1400, // Updated max width
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                height: 88, // Slightly taller for premium feel
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // LOGO
                    InkWell(
                      onTap: () => context.go('/'),
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.bookOpen,
                            color: AppColors.tertiary,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'The Tactile Archive',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                    
                    // CENTER NAV LINKS (Adaptive Experience)
                    Expanded(
                      child: ValueListenableBuilder<UserType>(
                        valueListenable: ApiService.experienceState,
                        builder: (context, activeExp, _) {
                          final isAuth = ApiService.isLoggedIn;
                          final isStudent = isAuth && activeExp == UserType.student;

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                if (isStudent) ...[
                                  _NavLink(
                                    label: 'Academic Home',
                                    isActive: location == '/student',
                                    onTap: () => context.go('/student'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Textbooks',
                                    isActive: location == '/browse',
                                    onTap: () => context.go('/browse'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Semester Planner',
                                    isActive: location == '/semester-planner',
                                    onTap: () => context.go('/semester-planner'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Study Assistant',
                                    isActive: location == '/study-assistant',
                                    onTap: () => context.go('/study-assistant'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Exchange Hubs',
                                    isActive: location == '/exchange-map',
                                    onTap: () => context.go('/exchange-map'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Sell / Lend',
                                    isActive: location.startsWith('/sell'),
                                    onTap: () {
                                      if (ApiService.providerEnabled) {
                                        context.go('/sell');
                                      } else {
                                        context.go('/profile');
                                      }
                                    },
                                  ),
                                ] else if (isAuth) ...[
                                  _NavLink(
                                    label: 'Reading Home',
                                    isActive: location == '/reader' || location == '/',
                                    onTap: () => context.go('/reader'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Discover',
                                    isActive: location == '/browse',
                                    onTap: () => context.go('/browse'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Bookshelf',
                                    isActive: location == '/library',
                                    onTap: () => context.go('/library'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Categories',
                                    isActive: location == '/categories',
                                    onTap: () => context.go('/categories'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Exchange Hubs',
                                    isActive: location == '/exchange-map',
                                    onTap: () => context.go('/exchange-map'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Sell / Lend',
                                    isActive: location.startsWith('/sell'),
                                    onTap: () {
                                      if (ApiService.providerEnabled) {
                                        context.go('/sell');
                                      } else {
                                        context.go('/profile');
                                      }
                                    },
                                  ),
                                ] else ...[
                                  _NavLink(
                                    label: 'Home',
                                    isActive: location == '/',
                                    onTap: () => context.go('/'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Browse',
                                    isActive: location == '/browse',
                                    onTap: () => context.go('/browse'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Categories',
                                    isActive: location == '/categories',
                                    onTap: () => context.go('/categories'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Exchange Hubs',
                                    isActive: location == '/exchange-map',
                                    onTap: () => context.go('/exchange-map'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'About Us',
                                    isActive: location == '/about',
                                    onTap: () => context.go('/about'),
                                  ),
                                  const SizedBox(width: 20),
                                  _NavLink(
                                    label: 'Contact',
                                    isActive: location == '/contact',
                                    onTap: () => context.go('/contact'),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 24),
                    
                    // RIGHT SIDE: SEARCH & NAV ICONS
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // SEARCH BAR
                        CompositedTransformTarget(
                          link: _searchLayerLink,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            width: _searchFocusNode.hasFocus ? 280 : 180, // Reduced width to prevent overflow
                            height: 40,
                            decoration: BoxDecoration(
                              color: _searchFocusNode.hasFocus
                                  ? Colors.white
                                  : AppColors.surfaceContainerHighest.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: _searchFocusNode.hasFocus
                                    ? AppColors.tertiary.withOpacity(0.5)
                                    : Colors.transparent,
                                width: 1,
                              ),
                              boxShadow: _searchFocusNode.hasFocus
                                  ? [
                                      BoxShadow(
                                        color: AppColors.tertiary.withOpacity(0.1),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : [],
                            ),
                            child: Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 16, right: 12),
                                  child: FaIcon(
                                    FontAwesomeIcons.magnifyingGlass,
                                    size: 14,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    onSubmitted: (value) {
                                      _searchFocusNode.unfocus();
                                      if (value.isNotEmpty) {
                                        context.go('/browse?search=${Uri.encodeComponent(value)}');
                                      }
                                    },
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: AppColors.onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Search books, authors, ISBN...',
                                      hintStyle: GoogleFonts.inter(
                                        color: AppColors.onSurfaceVariant.withOpacity(0.8),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                                if (_searchController.text.isNotEmpty)
                                  InkWell(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                    borderRadius: BorderRadius.circular(DSRadius.card),
                                    child: const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: FaIcon(
                                        FontAwesomeIcons.xmark,
                                        size: 14,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        
                        _IconBtn(
                          icon: FontAwesomeIcons.heart,
                          tooltip: 'Wishlist',
                          onTap: () => context.go('/favorites'),
                        ),
                        const SizedBox(width: 20),
                        BlocBuilder<CartBloc, CartState>(
                          builder: (context, cartState) {
                            int count = 0;
                            if (cartState is CartLoaded) {
                              count = cartState.cart.items.fold(0, (sum, i) => sum + i.quantity);
                            }
                            return _IconBtn(
                              icon: FontAwesomeIcons.cartShopping,
                              tooltip: 'Cart',
                              badgeCount: count,
                              onTap: () => context.go('/cart'),
                            );
                          },
                        ),
                        const SizedBox(width: 24),
                        
                        // AUTH BUTTON / AVATAR
                        ValueListenableBuilder<bool>(
                          valueListenable: ApiService.authState,
                          builder: (context, isLoggedIn, child) {
                            if (isLoggedIn) {
                              return PopupMenuButton<String>(
                                offset: const Offset(0, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppColors.tertiary.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppColors.tertiary.withOpacity(0.2),
                                        child: Text(
                                          (ApiService.userName ?? 'U')[0].toUpperCase(),
                                          style: GoogleFonts.inter(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        ApiService.userName ?? 'User',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: AppColors.primary,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                  ),
                                ),
                                onSelected: (value) async {
                                  switch (value) {
                                    case 'profile':
                                      context.go('/profile');
                                      break;
                                    case 'switch_experience':
                                      final target = ApiService.activeExperience == UserType.student
                                          ? UserType.reader
                                          : UserType.student;
                                      await ApiService.switchExperience(target);
                                      if (context.mounted) {
                                        context.go(target == UserType.student ? '/student' : '/reader');
                                      }
                                      break;
                                    case 'provider':
                                      if (ApiService.providerEnabled) {
                                        context.go('/provider');
                                      } else {
                                        context.go('/profile');
                                      }
                                      break;
                                    case 'wishlist':
                                      context.go('/favorites');
                                      break;
                                    case 'orders':
                                      context.go('/order-history');
                                      break;
                                    case 'books':
                                      context.go('/library');
                                      break;
                                    case 'settings':
                                      context.go('/account-settings');
                                      break;
                                    case 'logout':
                                      await ApiService.logout();
                                      if (context.mounted) context.go('/');
                                      break;
                                  }
                                },
                                itemBuilder: (context) {
                                  final isStudent = ApiService.activeExperience == UserType.student;
                                  final isProv = ApiService.providerEnabled;

                                  return [
                                    _buildPopupItem(
                                      'profile',
                                      FontAwesomeIcons.user,
                                      isStudent ? 'Academic Profile' : 'Reader Profile',
                                    ),
                                    _buildPopupItem(
                                      'switch_experience',
                                      isStudent ? FontAwesomeIcons.bookOpen : FontAwesomeIcons.graduationCap,
                                      isStudent ? 'Switch to Reader Mode' : 'Switch to Student Mode',
                                    ),
                                    _buildPopupItem(
                                      'provider',
                                      FontAwesomeIcons.store,
                                      isProv ? 'Provider Operating Hub' : 'Become a Provider',
                                    ),
                                    const PopupMenuDivider(),
                                    _buildPopupItem('wishlist', FontAwesomeIcons.heart, 'Wishlist'),
                                    _buildPopupItem('orders', FontAwesomeIcons.receipt, 'My Orders'),
                                    _buildPopupItem('books', FontAwesomeIcons.book, isStudent ? 'My Course Books' : 'Living Bookshelf'),
                                    _buildPopupItem('settings', FontAwesomeIcons.gear, 'Account Settings'),
                                    const PopupMenuDivider(),
                                    _buildPopupItem('logout', FontAwesomeIcons.arrowRightFromBracket, 'Logout', isDestructive: true),
                                  ];
                                },
                              );
                            }

                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () => context.push('/login'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: DSColors.deepForestGreen,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                  child: Text(
                                    'Log In',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => context.push('/register'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.onPrimary,
                                    elevation: 2,
                                    shadowColor: AppColors.primary.withOpacity(0.3),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  child: Text(
                                    'Sign Up',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
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

  PopupMenuItem<String> _buildPopupItem(
    String value,
    dynamic icon,
    String label, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? const Color(0xFFE74C3C) : AppColors.onSurface;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          FaIcon(icon, size: 16, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavLink({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 88, // Match navbar height for full hit area
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w600,
                  color: widget.isActive || _hovered
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              // Animated underline
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: widget.isActive || _hovered ? 1.0 : 0.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 3,
                  width: widget.isActive ? 24 : (_hovered ? 16 : 0),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  final dynamic icon;
  final VoidCallback onTap;
  final String tooltip;
  final int? badgeCount;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.badgeCount,
  });

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    Widget iconChild = FaIcon(
      widget.icon,
      size: 22,
      color: _hovered ? AppColors.tertiary : AppColors.primary.withOpacity(0.8),
    );

    if (widget.badgeCount != null && widget.badgeCount! > 0) {
      iconChild = Stack(
        clipBehavior: Clip.none,
        children: [
          iconChild,
          Positioned(
            top: -6,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: DSColors.accentTerracotta,
                borderRadius: BorderRadius.circular(DSRadius.md),
                boxShadow: [
                  BoxShadow(
                    color: DSColors.accentTerracotta.withOpacity(0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Center(
                child: Text(
                  widget.badgeCount! > 99 ? '99+' : '${widget.badgeCount}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _hovered ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: iconChild,
          ),
        ),
      ),
    );
  }
}
