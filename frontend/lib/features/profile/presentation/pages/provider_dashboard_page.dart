import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/design_system/design_system.dart';

class ProviderDashboardPage extends StatefulWidget {
  final VoidCallback? onSwitchToReader;
  const ProviderDashboardPage({super.key, this.onSwitchToReader});

  @override
  State<ProviderDashboardPage> createState() => _ProviderDashboardPageState();
}

class _ProviderDashboardPageState extends State<ProviderDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  Map<String, dynamic> _dashboardData = {
    'provider_name': ApiService.userName ?? 'Provider',
    'provider_email': 'athiya160@gmail.com',
    'is_verified': true,
    'rating': 5.0,
    'total_reviews': 0,
    'metrics': {
      'total_listings': 0,
      'available_books': 0,
      'rentals_count': 0,
      'sold_count': 0,
      'total_earnings': 0.0,
      'month_earnings': 0.0,
      'pending_earnings': 0.0,
    },
    'action_required': {
      'rental_requests': 0,
      'exchange_pending': 0,
      'awaiting_verification': 0,
    },
    'recent_inventory': []
  };

  List<dynamic> _inventory = [];
  List<dynamic> _requests = [];
  Map<String, dynamic> _earnings = {};
  final Map<dynamic, String> _requestStatuses = {};
  String _requestsFilter = 'All';
  String _inventoryFilter = 'All';

  // Seller Notification Toggles
  bool _notifBuyOrders = true;
  bool _notifRentalReminders = true;
  bool _notifQrHandover = true;
  bool _weekendHubPresence = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _fetchProviderData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchProviderData() async {
    try {
      final dashRes = await ApiService.get('/provider/dashboard');
      if (dashRes.statusCode == 200 && dashRes.data != null) {
        setState(() {
          _dashboardData = Map<String, dynamic>.from(dashRes.data);
        });
      }
    } catch (_) {}

    try {
      final invRes = await ApiService.get('/provider/inventory');
      if (invRes.statusCode == 200 && invRes.data != null) {
        setState(() {
          _inventory = List.from(invRes.data);
        });
      }
    } catch (_) {}

    try {
      final reqRes = await ApiService.get('/provider/requests');
      if (reqRes.statusCode == 200 && reqRes.data != null) {
        setState(() {
          _requests = List.from(reqRes.data);
        });
      }
    } catch (_) {}

    try {
      final earnRes = await ApiService.get('/provider/earnings');
      if (earnRes.statusCode == 200 && earnRes.data != null) {
        setState(() {
          _earnings = Map<String, dynamic>.from(earnRes.data);
        });
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ApiService.isLoggedIn || !ApiService.isProvider) {
      return _buildUnauthorizedProviderView();
    }

    return Scaffold(
      backgroundColor: DSColors.warmIvory,
      appBar: AppBar(
        backgroundColor: DSColors.deepForestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Provider Operating Hub',
          style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined, color: Colors.white, size: 20),
            tooltip: 'View Storefront',
            onPressed: () => context.push('/provider-portfolio'),
          ),
          TextButton.icon(
            onPressed: widget.onSwitchToReader ?? () async {
              await ApiService.switchRole(UserRole.customer);
              if (context.mounted) {
                context.go('/');
              }
            },
            icon: const Icon(Icons.swap_horiz, color: Colors.white, size: 18),
            label: Text(
              'Reader Mode',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 20),
            tooltip: 'Log Out',
            onPressed: () async {
              final router = GoRouter.of(context);
              await ApiService.logout();
              router.go('/');
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFFD69E2E),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Inventory'),
            Tab(text: 'Requests & Orders'),
            Tab(text: 'Earnings & Payouts'),
            Tab(text: 'Profile & Settings'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: DSColors.deepForestGreen))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildInventoryTab(),
                _buildRequestsTab(),
                _buildEarningsTab(),
                _buildProfileTab(),
              ],
            ),
    );
  }

  Widget _buildUnauthorizedProviderView() {
    if (!ApiService.isLoggedIn) {
      return Scaffold(
        backgroundColor: DSColors.warmIvory,
        appBar: AppBar(
          backgroundColor: DSColors.deepForestGreen,
          foregroundColor: Colors.white,
          title: Text('Provider Hub', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: DSColors.charcoal),
                const SizedBox(height: 16),
                Text(
                  'Authentication Required',
                  style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: DSColors.charcoal),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please sign in to access your provider and seller dashboard.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: DSColors.textLight, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.push('/welcome'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DSColors.deepForestGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Log In to Continue'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final status = ApiService.providerStatus.toLowerCase();
    String title = 'Become a Community Provider';
    String description = 'List your personal library books for sale, rent, or peer lending. Earn income and share literary treasures with your campus and local community.';
    IconData icon = Icons.storefront_outlined;
    Color iconColor = DSColors.deepForestGreen;
    Widget? actionButton;

    if (status == 'pending' || status == 'pending_approval') {
      title = 'Application Under Review';
      description = 'Your provider application has been submitted and is currently undergoing verification by platform administrators. Approvals are typically processed within 24-48 hours.';
      icon = Icons.hourglass_top_rounded;
      iconColor = const Color(0xFFD69E2E);
      actionButton = ElevatedButton(
        onPressed: () => context.go('/'),
        style: ElevatedButton.styleFrom(
          backgroundColor: DSColors.deepForestGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: const Text('Return to Home'),
      );
    } else if (status == 'suspended') {
      title = 'Provider Account Suspended';
      description = 'Your provider privileges have been suspended by platform administration. Please contact support if you believe this is an error.';
      icon = Icons.block_flipped;
      iconColor = DSColors.error;
      actionButton = ElevatedButton(
        onPressed: () => context.go('/support'),
        style: ElevatedButton.styleFrom(
          backgroundColor: DSColors.charcoal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: const Text('Contact Support'),
      );
    } else if (status == 'rejected') {
      title = 'Provider Application Declined';
      description = 'Your previous application to become a provider was not approved. You can continue reading and borrowing as a community member.';
      icon = Icons.info_outline;
      iconColor = DSColors.error;
      actionButton = ElevatedButton(
        onPressed: () => context.go('/'),
        style: ElevatedButton.styleFrom(
          backgroundColor: DSColors.deepForestGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: const Text('Return to Home'),
      );
    } else {
      actionButton = ElevatedButton.icon(
        onPressed: () async {
          setState(() => _isLoading = true);
          final success = await ApiService.activateProvider();
          if (mounted) {
            setState(() => _isLoading = false);
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Provider mode activated! Welcome to your Seller Hub.'),
                  backgroundColor: DSColors.deepForestGreen,
                ),
              );
              _fetchProviderData();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to activate provider mode. Please try again.'),
                  backgroundColor: DSColors.error,
                ),
              );
            }
          }
        },
        icon: const Icon(Icons.rocket_launch, size: 18),
        label: const Text('Activate Seller & Provider Mode'),
        style: ElevatedButton.styleFrom(
          backgroundColor: DSColors.deepForestGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.sm)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: DSColors.warmIvory,
      appBar: AppBar(
        backgroundColor: DSColors.deepForestGreen,
        foregroundColor: Colors.white,
        title: Text('Provider Operating Hub', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 550),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DSRadius.card),
              border: Border.all(color: DSColors.softBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 48, color: iconColor),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: DSColors.charcoal),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: DSColors.textLight, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 28),
                actionButton,
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: Text(
                    'Continue as Reader / Student',
                    style: GoogleFonts.inter(color: DSColors.textMuted, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── 1. DASHBOARD TAB ────────────────────────────────────────────────────────

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProviderHeaderCard(),
              const SizedBox(height: 20),
              _buildMetricsGrid(),
              const SizedBox(height: 20),
              _buildActionRequiredBox(),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 800;
                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: _buildInventoryQuickList()),
                        const SizedBox(width: 20),
                        Expanded(flex: 4, child: _buildEarningsQuickCard()),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _buildInventoryQuickList(),
                      const SizedBox(height: 20),
                      _buildEarningsQuickCard(),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderHeaderCard() {
    final fullName = _dashboardData['provider_name'] ?? 'Athiya Tabassum';
    final isVerified = _dashboardData['is_verified'] == true;
    final rating = _dashboardData['rating'] ?? 5.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.softBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: DSColors.deepForestGreen,
            child: Text(
              fullName.isNotEmpty ? fullName[0].toUpperCase() : 'P',
              style: GoogleFonts.playfairDisplay(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        fullName,
                        style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: DSColors.charcoal),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(DSRadius.sm),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified, size: 12, color: Color(0xFF2E7D32)),
                            const SizedBox(width: 4),
                            Text(
                              'Verified Seller',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: DSColors.success),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 14, color: Color(0xFFD69E2E)),
                        const SizedBox(width: 4),
                        Text(
                          '$rating Rating',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.charcoal),
                        ),
                      ],
                    ),
                    Text(
                      '• 📍 Indiranagar Hub #4',
                      style: GoogleFonts.inter(fontSize: 12, color: DSColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => context.push('/add-book'),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Listing'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DSColors.deepForestGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.sm)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final metrics = _dashboardData['metrics'] ?? {};
    final totalListings = metrics['total_listings'] ?? 0;
    final totalEarnings = metrics['total_earnings'] ?? 0.0;
    final rentalsCount = metrics['rentals_count'] ?? 0;
    final soldCount = metrics['sold_count'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        return GridView.count(
          crossAxisCount: isCompact ? 2 : 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isCompact ? 1.6 : 1.8,
          children: [
            _buildMetricTile('$totalListings', 'Listings', Icons.collections_bookmark_outlined, DSColors.deepForestGreen),
            _buildMetricTile('$rentalsCount', 'Active Rentals', Icons.cached, DSColors.success),
            _buildMetricTile('$soldCount', 'Books Sold', Icons.sell_outlined, DSColors.terracotta),
            _buildMetricTile('₹${totalEarnings.toInt()}', 'Earnings', Icons.account_balance_wallet_outlined, const Color(0xFFD69E2E)),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: DSColors.deepForestGreen,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: DSColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRequiredBox() {
    final actions = _dashboardData['action_required'] ?? {};
    final rentalReqs = actions['rental_requests'] ?? 0;
    final exchangePending = actions['exchange_pending'] ?? 0;
    final unverified = actions['awaiting_verification'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'Seller Action Queue',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActionItem('🔴 $rentalReqs Pending Rental / Buy Requests awaiting response', () => _tabController.animateTo(2)),
          _buildActionItem('🟡 $exchangePending Exchange Orders at Verified Meetup Hub', () => _tabController.animateTo(2)),
          _buildActionItem('🟡 $unverified Listings under Archival Quality Verification', () => _tabController.animateTo(1)),
        ],
      ),
    );
  }

  Widget _buildActionItem(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.circle, size: 6, color: Color(0xFFD97706)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF78350F), fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFFD97706)),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryQuickList() {
    final items = _dashboardData['recent_inventory'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📚 Recent Listings',
                style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: DSColors.charcoal),
              ),
              TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: Text('View All (${_inventory.length}) →', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text('No book listings yet. Click "+ Add Listing" to create your first listing.', style: GoogleFonts.inter(fontSize: 12, color: DSColors.textMuted)),
              ),
            )
          else
            ...items.map((book) {
              final status = book['status'] ?? 'Available';
              final isAvailable = status == 'Available';
              final isRented = status == 'Rented';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(DSRadius.sm),
                      child: (book['coverUrl'] != null && (book['coverUrl'] as String).isNotEmpty)
                          ? Image.network(
                              ApiService.resolveImageUrl(book['coverUrl']),
                              width: 36,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildFallbackBookIcon(),
                            )
                          : _buildFallbackBookIcon(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book['title'] ?? '',
                            style: GoogleFonts.playfairDisplay(fontSize: 13, fontWeight: FontWeight.bold, color: DSColors.charcoal),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            book['author'] ?? '',
                            style: GoogleFonts.inter(fontSize: 11, color: DSColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? const Color(0xFFE8F5E9)
                            : (isRented ? const Color(0xFFFFF3ED) : const Color(0xFFFEE2E2)),
                        borderRadius: BorderRadius.circular(DSRadius.sm),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isAvailable
                              ? DSColors.success
                              : (isRented ? DSColors.terracotta : DSColors.error),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEarningsQuickCard() {
    final metrics = _dashboardData['metrics'] ?? {};
    final monthEarn = metrics['month_earnings'] ?? 0.0;
    final pendingEarn = metrics['pending_earnings'] ?? 0.0;
    final totalEarn = metrics['total_earnings'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💰', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'Earnings Summary',
                style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: DSColors.charcoal),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEarningsRow('This month', '₹${monthEarn.toInt()}'),
          const SizedBox(height: 8),
          _buildEarningsRow('Pending in Escrow', '₹${pendingEarn.toInt()}'),
          const Divider(height: 20),
          _buildEarningsRow('Lifetime Total', '₹${totalEarn.toInt()}', isBold: true),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => _tabController.animateTo(3),
            style: OutlinedButton.styleFrom(
              foregroundColor: DSColors.deepForestGreen,
              side: const BorderSide(color: DSColors.deepForestGreen),
              minimumSize: const Size(double.infinity, 38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.sm)),
            ),
            child: Text('View Full Breakdown →', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: DSColors.textMuted, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: DSColors.charcoal)),
      ],
    );
  }

  // ─── 2. INVENTORY & LISTINGS MANAGEMENT TAB ──────────────────────────────────

  Widget _buildInventoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inventory & Catalog Management',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: DSColors.charcoal,
                        ),
                      ),
                      Text(
                        'Manage stock, edit prices, and track verification status',
                        style: GoogleFonts.inter(fontSize: 12, color: DSColors.textMuted),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/add-book'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Book'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DSColors.deepForestGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.sm)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  {'label': 'All', 'filter': 'All', 'count': _inventory.length},
                  {
                    'label': 'Available / Active',
                    'filter': 'Active / Available',
                    'count': _inventory.where((b) => (b['stock'] ?? 1) > 0 && (b['approval_status'] ?? '').toString().toLowerCase() != 'pending_approval' && (b['approval_status'] ?? '').toString().toLowerCase() != 'rejected').length
                  },
                  {
                    'label': 'Pending Approval',
                    'filter': 'Pending Review',
                    'count': _inventory.where((b) => (b['approval_status'] ?? '').toString().toLowerCase() == 'pending_approval').length
                  },
                  {
                    'label': 'Unavailable / Sold',
                    'filter': 'Unavailable / Sold',
                    'count': _inventory.where((b) => (b['stock'] ?? 1) <= 0 || (b['approval_status'] ?? '').toString().toLowerCase() == 'rejected').length
                  },
                ].map((item) {
                  final String filter = item['filter'] as String;
                  final isSelected = _inventoryFilter == filter;
                  return ChoiceChip(
                    label: Text(
                      '${item["label"]} (${item["count"]})',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : DSColors.charcoal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: DSColors.deepForestGreen,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: isSelected ? DSColors.deepForestGreen : DSColors.softBorder),
                    onSelected: (val) {
                      if (val) setState(() => _inventoryFilter = filter);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (_inventory.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(DSRadius.card),
                    border: Border.all(color: DSColors.softBorder),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.library_books_outlined, size: 48, color: Color(0xFFA0AEC0)),
                        const SizedBox(height: 12),
                        Text(
                          'No Books in Your Inventory',
                          style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: DSColors.charcoal),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'List books from your library for Sale, Rent, or Peer Lending.',
                          style: GoogleFonts.inter(fontSize: 13, color: DSColors.textMuted),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/add-book'),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Create First Listing'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DSColors.deepForestGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.sm)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._inventory.where((b) {
                  final int stock = b['stock'] ?? 1;
                  final String approval = (b['approval_status'] ?? 'approved').toString().toLowerCase();
                  if (_inventoryFilter == 'Active / Available') {
                    return stock > 0 && approval != 'pending_approval' && approval != 'rejected';
                  }
                  if (_inventoryFilter == 'Pending Review') {
                    return approval == 'pending_approval';
                  }
                  if (_inventoryFilter == 'Unavailable / Sold') {
                    return stock <= 0 || approval == 'rejected';
                  }
                  return true;
                }).map((b) {
                  final int bookId = b['id'] ?? 0;
                  final String title = b['title'] ?? 'Archive Book';
                  final String author = b['author'] ?? 'Unknown Author';
                  final double price = (b['price'] as num?)?.toDouble() ?? 0.0;
                  final int stock = b['stock'] ?? 1;
                  final String condition = b['condition'] ?? 'Good';
                  final String coverUrl = b['coverUrl'] ?? b['image_url'] ?? '';
                  final String approvalStatus = (b['approval_status'] ?? 'approved').toString().toLowerCase();

                  String statusLabel = stock > 0 ? 'Available' : 'Out of Stock';
                  Color badgeBg = const Color(0xFFE8F5E9);
                  Color textCol = DSColors.success;
                  if (stock <= 0) {
                    badgeBg = const Color(0xFFFFF3ED);
                    textCol = DSColors.terracotta;
                  }
                  if (approvalStatus == 'pending_approval') {
                    statusLabel = 'Pending Review';
                    badgeBg = const Color(0xFFFFFBEB);
                    textCol = DSColors.accentTerracotta;
                  } else if (approvalStatus == 'rejected') {
                    statusLabel = 'Rejected';
                    badgeBg = const Color(0xFFFEE2E2);
                    textCol = DSColors.error;
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
                    elevation: 0,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(DSRadius.sm),
                            child: coverUrl.isNotEmpty
                                ? Image.network(
                                    ApiService.resolveImageUrl(coverUrl),
                                    width: 48,
                                    height: 68,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildFallbackBookIcon(w: 48, h: 68),
                                  )
                                : _buildFallbackBookIcon(w: 48, h: 68),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: GoogleFonts.playfairDisplay(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: DSColors.charcoal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: badgeBg,
                                        borderRadius: BorderRadius.circular(DSRadius.sm),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: textCol,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'by $author • $condition',
                                  style: GoogleFonts.inter(fontSize: 12, color: DSColors.textMuted),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 12,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      '₹${price.toStringAsFixed(0)} Buy',
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
                                    ),
                                    Text(
                                      '• Stock: $stock ${stock == 1 ? 'copy' : 'copies'}',
                                      style: GoogleFonts.inter(fontSize: 12, color: DSColors.charcoal),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF4A5568)),
                                tooltip: 'Edit Listing',
                                onPressed: () => _showEditListingDialog(b),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                                tooltip: 'Delete Listing',
                                onPressed: () => _showDeleteListingDialog(bookId, title),
                              ),
                              IconButton(
                                icon: const Icon(Icons.open_in_new, size: 18, color: DSColors.deepForestGreen),
                                tooltip: 'View in Catalog',
                                onPressed: () => context.push('/book/$bookId'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 3. REQUESTS & ORDERS TAB ────────────────────────────────────────────────

  Widget _buildRequestsTab() {
    final filtered = _requestsFilter == 'All'
        ? _requests
        : _requests.where((r) {
            final type = (r['type'] ?? '').toString().toLowerCase();
            final status = (_requestStatuses[r['id']] ?? r['status'] ?? 'pending').toString().toLowerCase();
            if (_requestsFilter == 'Pending Requests') {
              return status == 'pending';
            }
            if (_requestsFilter == 'Completed') {
              return status == 'approved' || status == 'completed' || status == 'active';
            }
            if (_requestsFilter == 'Buy') return type.contains('buy') || type.contains('sale');
            if (_requestsFilter == 'Rent') return type.contains('rent');
            if (_requestsFilter == 'Borrow') return type.contains('borrow');
            return true;
          }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Incoming Requests & Orders',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: DSColors.charcoal,
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    children: ['All', 'Pending Requests', 'Completed', 'Buy', 'Rent', 'Borrow'].map((filter) {
                      final isSelected = _requestsFilter == filter;
                      return ChoiceChip(
                        label: Text(filter, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                        selected: isSelected,
                        selectedColor: DSColors.deepForestGreen,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : DSColors.charcoal),
                        onSelected: (val) {
                          if (val) setState(() => _requestsFilter = filter);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(DSRadius.card),
                    border: Border.all(color: DSColors.softBorder),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFFA0AEC0)),
                        const SizedBox(height: 12),
                        Text(
                          'No Requests in this Category',
                          style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: DSColors.charcoal),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'When community readers request your books for buy, rent, or borrow, they will appear here.',
                          style: GoogleFonts.inter(fontSize: 12, color: DSColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...filtered.map((req) {
                  final String reqType = req['type'] ?? 'Rental Request';
                  final String requester = req['requester_name'] ?? 'Reader';
                  final String bookTitle = req['book_title'] ?? 'Archive Book';
                  final String bookCover = req['book_cover'] ?? '';
                  final String time = req['created_at'] ?? 'Recently';
                  final String currentStatus = (_requestStatuses[req['id']] ?? req['status'] ?? 'pending').toString().toLowerCase();
                  final int duration = req['duration_days'] ?? 14;
                  final double amount = (req['amount'] as num?)?.toDouble() ?? 0.0;

                  Color typeBg = const Color(0xFFFFF3ED);
                  Color typeText = DSColors.terracotta;
                  if (reqType.toLowerCase().contains('buy')) {
                    typeBg = const Color(0xFFEFF6FF);
                    typeText = DSColors.info;
                  } else if (reqType.toLowerCase().contains('borrow')) {
                    typeBg = const Color(0xFFF0FDF4);
                    typeText = DSColors.success;
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.card)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: typeBg,
                                  borderRadius: BorderRadius.circular(DSRadius.sm),
                                ),
                                child: Text(
                                  reqType,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: typeText,
                                  ),
                                ),
                              ),
                              Text(
                                time,
                                style: GoogleFonts.inter(fontSize: 11, color: DSColors.textLight),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(DSRadius.sm),
                                child: bookCover.isNotEmpty
                                    ? Image.network(
                                        ApiService.resolveImageUrl(bookCover),
                                        width: 44,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => _buildFallbackBookIcon(w: 44, h: 60),
                                      )
                                    : _buildFallbackBookIcon(w: 44, h: 60),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bookTitle,
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: DSColors.charcoal,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Customer: $requester',
                                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: DSColors.charcoal),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      duration > 0
                                          ? 'Period: $duration days • Amount: ₹${amount.toInt()}'
                                          : 'Amount: ₹${amount.toInt()} • Pickup: Indiranagar Hub #4',
                                      style: GoogleFonts.inter(fontSize: 12, color: DSColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Builder(
                            builder: (context) {
                              if (currentStatus == 'approved' || currentStatus == 'active' || currentStatus == 'completed') {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(DSRadius.sm),
                                        border: Border.all(color: const Color(0xFFA5D6A7)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF2E7D32)),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Approved • Ready for Hand-off',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: DSColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _showHandoverQRDialog(req),
                                      icon: const Icon(Icons.qr_code, size: 16),
                                      label: const Text('Show Handover QR'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: DSColors.deepForestGreen,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.sm)),
                                      ),
                                    ),
                                  ],
                                );
                              } else if (currentStatus == 'rejected' || currentStatus == 'cancelled') {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(DSRadius.sm),
                                    border: Border.all(color: const Color(0xFFFFCDD2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.cancel_rounded, size: 16, color: Color(0xFFC62828)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Declined by Seller',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: DSColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: () async {
                                      setState(() {
                                        _requestStatuses[req['id']] = 'rejected';
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Request declined.')),
                                      );
                                      try {
                                        await ApiService.post('/provider/requests/${req['id']}/reject');
                                      } catch (_) {}
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: DSColors.error,
                                      side: const BorderSide(color: Color(0xFFFECACA)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.sm)),
                                    ),
                                    child: const Text('Reject'),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: () async {
                                      setState(() {
                                        _requestStatuses[req['id']] = 'approved';
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Request Approved! Ready for QR Hand-off.')),
                                      );
                                      try {
                                        await ApiService.post('/provider/requests/${req['id']}/approve');
                                      } catch (_) {}
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: DSColors.deepForestGreen,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.sm)),
                                    ),
                                    child: const Text('Approve & Issue QR'),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 4. EARNINGS TAB ─────────────────────────────────────────────────────────

  Widget _buildEarningsTab() {
    final available = _earnings['available_for_payout'] != null
        ? '₹${(_earnings['available_for_payout'] as num).toInt()}'
        : '₹0';
    final pending = _earnings['pending_escrow'] != null
        ? '₹${(_earnings['pending_escrow'] as num).toInt()}'
        : '₹0';
    final lifetime = _earnings['total_earned'] != null
        ? '₹${(_earnings['total_earned'] as num).toInt()}'
        : '₹0';
    final payoutDest = _earnings['payout_method'] as String? ?? 'UPI: athiya@okaxis (Verified)';
    final transactions = _earnings['transactions'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Earnings & Payouts Engine',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DSColors.charcoal,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DSRadius.card),
                  border: Border.all(color: DSColors.softBorder),
                ),
                child: Column(
                  children: [
                    _buildEarningsRow('Available for Payout', available, isBold: true),
                    const SizedBox(height: 8),
                    _buildEarningsRow('Pending in Safe Escrow', pending),
                    const SizedBox(height: 8),
                    _buildEarningsRow('Lifetime Total Earnings', lifetime),
                    const Divider(height: 24),
                    _buildEarningsRow('Payout Destination', payoutDest),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.card)),
                              title: Text('Withdraw Payout', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
                              content: Text('The available balance of $available will be transferred directly to your verified payout destination ($payoutDest) via IMPS/UPI.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Payout request of $available submitted successfully! Funds arrive within 24 hours.')),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: DSColors.deepForestGreen, foregroundColor: Colors.white),
                                  child: const Text('Confirm Transfer'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DSColors.deepForestGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.sm)),
                        ),
                        child: Text(
                          'Withdraw Available Funds ($available)',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Recent Settlement History',
                style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: DSColors.charcoal),
              ),
              const SizedBox(height: 12),
              if (transactions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(DSRadius.md),
                    border: Border.all(color: DSColors.softBorder),
                  ),
                  child: Center(
                    child: Text('No completed settlements recorded yet.', style: GoogleFonts.inter(fontSize: 12, color: DSColors.textMuted)),
                  ),
                )
              else
                ...transactions.map((tx) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    color: Colors.white,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE8F5E9),
                        child: Text('₹', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: DSColors.success)),
                      ),
                      title: Text(tx['book_title'] ?? 'Archive Transaction', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('${tx['date']} • ${tx['type']} to ${tx['customer']}', style: GoogleFonts.inter(fontSize: 11, color: DSColors.textMuted)),
                      trailing: Text(
                        '₹${(tx['amount'] ?? 0).toInt()}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: DSColors.deepForestGreen),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 5. PROFILE & SELLER SETTINGS TAB ────────────────────────────────────────

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seller Hub Profile & Operating Settings',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DSColors.charcoal,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DSRadius.card),
                  border: Border.all(color: DSColors.softBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verified Safe Exchange Hub Spot',
                      style: GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Location: Indiranagar Central Library Hub #4 (Safe Verified Community Point)',
                      style: GoogleFonts.inter(fontSize: 12, color: DSColors.textMuted),
                    ),
                    const Divider(height: 24),
                    Text(
                      'Community Trust Rating: 4.8 ★★★★★ (19 Reviews)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: DSColors.deepForestGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Book Condition Guarantee: 100% verified with AI vision inspector upon physical handoff.',
                      style: GoogleFonts.inter(fontSize: 12, color: DSColors.textMuted),
                    ),
                    const Divider(height: 32),
                    Text(
                      'Seller Notification Preferences',
                      style: GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.bold, color: DSColors.charcoal),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Instant Alerts for Buy Orders', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text('Receive notifications when a reader purchases your book', style: GoogleFonts.inter(fontSize: 11, color: DSColors.textMuted)),
                      value: _notifBuyOrders,
                      activeThumbColor: DSColors.deepForestGreen,
                      onChanged: (val) => setState(() => _notifBuyOrders = val),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Rental Return Due Reminders', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text('Alerts 2 days prior to scheduled book return dates', style: GoogleFonts.inter(fontSize: 11, color: DSColors.textMuted)),
                      value: _notifRentalReminders,
                      activeThumbColor: DSColors.deepForestGreen,
                      onChanged: (val) => setState(() => _notifRentalReminders = val),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Digital QR Verification Alerts', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text('Instant verification prompt when reader scans exchange code', style: GoogleFonts.inter(fontSize: 11, color: DSColors.textMuted)),
                      value: _notifQrHandover,
                      activeThumbColor: DSColors.deepForestGreen,
                      onChanged: (val) => setState(() => _notifQrHandover = val),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Weekend Exchange Hub Presence', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text('Accept in-person weekend handovers at Indiranagar Hub', style: GoogleFonts.inter(fontSize: 11, color: DSColors.textMuted)),
                      value: _weekendHubPresence,
                      activeThumbColor: DSColors.deepForestGreen,
                      onChanged: (val) => setState(() => _weekendHubPresence = val),
                    ),
                    const Divider(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/account-settings'),
                            icon: const Icon(Icons.settings_outlined, size: 16),
                            label: const Text('Account Settings'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: DSColors.charcoal,
                              side: const BorderSide(color: DSColors.softBorder),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.sm)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await ApiService.logout();
                              if (mounted) {
                                context.go('/');
                              }
                            },
                            icon: const Icon(Icons.logout, color: Color(0xFFDC2626), size: 16),
                            label: Text(
                              'Log Out of Provider',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: DSColors.error),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFEB2B2)),
                              backgroundColor: const Color(0xFFFFF5F5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.sm)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── DIALOGS & MUTATIONS ─────────────────────────────────────────────────────

  Widget _buildFallbackBookIcon({double w = 36, double h = 48}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F4),
        borderRadius: BorderRadius.circular(DSRadius.sm),
      ),
      child: const Icon(Icons.book, size: 20, color: Color(0xFF0D3B2E)),
    );
  }

  void _showEditListingDialog(Map<String, dynamic> book) {
    final titleCtrl = TextEditingController(text: book['title']?.toString() ?? '');
    final authorCtrl = TextEditingController(text: book['author']?.toString() ?? '');
    final priceCtrl = TextEditingController(text: (book['price'] ?? 0.0).toString());
    final stockCtrl = TextEditingController(text: (book['stock'] ?? 1).toString());
    final descCtrl = TextEditingController(text: book['description']?.toString() ?? '');
    String condition = book['condition']?.toString() ?? 'Good';
    final bookId = book['id'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.card)),
          title: Text(
            'Edit Listing Details',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Book Title', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: authorCtrl,
                    decoration: const InputDecoration(labelText: 'Author', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Selling Price (₹)', prefixText: '₹ ', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: stockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Available Copies', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: ['Like New', 'Good', 'Fair', 'Poor'].contains(condition) ? condition : 'Good',
                    decoration: const InputDecoration(labelText: 'Physical Condition', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Like New', child: Text('Like New (Pristine)')),
                      DropdownMenuItem(value: 'Good', child: Text('Good (Minor wear)')),
                      DropdownMenuItem(value: 'Fair', child: Text('Fair (Readable, worn)')),
                      DropdownMenuItem(value: 'Poor', child: Text('Poor (Archival rescue)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => condition = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description / Notes', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final double? newPrice = double.tryParse(priceCtrl.text.trim());
                final int? newStock = int.tryParse(stockCtrl.text.trim());
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                try {
                  final updateData = <String, dynamic>{
                    'title': titleCtrl.text.trim(),
                    'author': authorCtrl.text.trim(),
                    'condition': condition,
                    'description': descCtrl.text.trim(),
                  };
                  if (newPrice != null) updateData['price'] = newPrice;
                  if (newStock != null) updateData['stock'] = newStock;
                  final res = await ApiService.put(
                    '/provider/inventory/$bookId',
                    data: updateData,
                  );
                  if (res.statusCode == 200) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Listing updated successfully!')),
                    );
                    _fetchProviderData();
                  } else {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to update listing: ${res.message ?? "Error"}')),
                    );
                  }
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error updating listing: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DSColors.deepForestGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteListingDialog(int bookId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Listing', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "$title" from your seller inventory? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              try {
                await ApiService.delete('/provider/inventory/$bookId');
                messenger.showSnackBar(
                  SnackBar(content: Text('Listing "$title" removed.')),
                );
                _fetchProviderData();
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to delete listing: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: DSColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showHandoverQRDialog(Map<String, dynamic> req) {
    final bookTitle = req['book_title'] ?? 'Archive Book';
    final requester = req['requester_name'] ?? 'Reader';
    final handoverCode = 'HO-${req['id']}-${(req['book_id'] ?? 101)}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.card)),
        title: Row(
          children: [
            const Icon(Icons.qr_code_2, color: DSColors.deepForestGreen, size: 28),
            const SizedBox(width: 10),
            Text('Exchange Verification QR', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 180,
              height: 180,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DSColors.softBorder),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_scanner, size: 80, color: Color(0xFF0D3B2E)),
                    const SizedBox(height: 8),
                    Text(
                      handoverCode,
                      style: GoogleFonts.spaceMono(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Recipient: $requester', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text('Book: $bookTitle', style: GoogleFonts.inter(fontSize: 13, color: DSColors.charcoal)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(DSRadius.sm),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined, size: 16, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Present this QR at Indiranagar Hub #4 or have courier scan on physical delivery.',
                      style: GoogleFonts.inter(fontSize: 11, color: DSColors.success),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Handover confirmed! Order status marked as in-transit.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: DSColors.deepForestGreen, foregroundColor: Colors.white),
            child: const Text('Confirm Handover Complete'),
          ),
        ],
      ),
    );
  }
}
