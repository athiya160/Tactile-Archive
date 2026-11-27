import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:libri_flow/core/widgets/ivory_scaffold.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/api_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _apiClient = sl<ApiClient>();
  bool _isLoading = true;
  String? _errorMessage;

  // Data state
  Map<String, dynamic> _stats = {};
  List<dynamic> _users = [];
  List<dynamic> _books = [];
  List<dynamic> _orders = [];
  List<dynamic> _pendingBooks = [];
  List<dynamic> _providers = [];
  List<dynamic> _activityLogs = [];
  String _catalogSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _apiClient.getJson('/admin/stats'),
        _apiClient.getJson('/admin/users'),
        _apiClient.getJson('/admin/books'),
        _apiClient.getJson('/admin/orders'),
        _apiClient.getJson('/admin/pending-books'),
        _apiClient.getJson('/admin/providers'),
        _apiClient.getJson('/admin/activity'),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as Map<String, dynamic>? ?? {};
        _users = results[1] as List<dynamic>? ?? [];
        _books = results[2] as List<dynamic>? ?? [];
        _orders = results[3] as List<dynamic>? ?? [];
        _pendingBooks = results[4] as List<dynamic>? ?? [];
        _providers = results[5] as List<dynamic>? ?? [];
        _activityLogs = results[6] as List<dynamic>? ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load admin data: $e';
      });
    }
  }

  // --- API Mutation Handlers ---

  Future<void> _updateUserRole(int userId, String level, bool isAdmin, {bool? providerEnabled}) async {
    try {
      final body = <String, dynamic>{'level': level, 'is_admin': isAdmin};
      if (providerEnabled != null) {
        body['provider_enabled'] = providerEnabled;
        body['role'] = providerEnabled ? 'provider' : 'customer';
      }
      await _apiClient.putJson('/admin/users/$userId/role', body: body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User role updated successfully')),
      );
      _loadAllData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update role: $e')),
      );
    }
  }

  Future<void> _updateProviderStatus(int providerId, String status) async {
    try {
      await _apiClient.putJson(
        '/admin/providers/$providerId/status',
        body: {'status': status},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Provider status updated to $status')),
      );
      _loadAllData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update provider status: $e')),
      );
    }
  }

  Future<void> _deleteBook(int bookId) async {
    try {
      await _apiClient.deleteJson('/admin/books/$bookId');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book deleted successfully')),
      );
      _loadAllData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete book: $e')),
      );
    }
  }

  Future<void> _updateOrderStatus(int orderId, String status) async {
    try {
      await _apiClient.putJson(
        '/admin/orders/$orderId/status',
        body: {'status': status},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order status updated successfully')),
      );
      _loadAllData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  Future<void> _approveBook(int bookId, String notes) async {
    try {
      await _apiClient.postJson(
        '/admin/books/$bookId/approve',
        body: {'notes': notes},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book approved and verified successfully')),
      );
      _loadAllData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve book: $e')),
      );
    }
  }

  Future<void> _rejectBook(int bookId, String notes) async {
    try {
      await _apiClient.postJson(
        '/admin/books/$bookId/reject',
        body: {'notes': notes},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book listing rejected')),
      );
      _loadAllData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject book: $e')),
      );
    }
  }

  // --- Component Builders ---

  @override
  Widget build(BuildContext context) {
    // 0. Authorization Gate: Never expose admin controls to ordinary users
    if (!ApiService.isLoggedIn || !ApiService.isAdmin) {
      return IvoryScaffold(
        title: 'Admin Access Required',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DSColors.primary),
          onPressed: () => context.go('/'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_person_outlined, size: 64, color: DSColors.error),
                const SizedBox(height: 16),
                Text(
                  'Restricted Administrator Portal',
                  style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: DSColors.primary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Access to this area is restricted to verified administrators only. Your current session does not hold administrative privileges.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: DSColors.textLight, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(backgroundColor: DSColors.primary, foregroundColor: Colors.white),
                  child: const Text('Return to Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return IvoryScaffold(
      title: 'Admin Operating Hub',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: DSColors.primary),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: DSColors.primary),
          tooltip: 'Refresh Platform State',
          onPressed: _loadAllData,
        ),
        const SizedBox(width: DSSpacing.sm),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: DSColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(DSSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage!, style: const TextStyle(color: DSColors.error)),
                        const SizedBox(height: DSSpacing.md),
                        ElevatedButton(
                          onPressed: _loadAllData,
                          style: ElevatedButton.styleFrom(backgroundColor: DSColors.primary),
                          child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    SizedBox(height: 64 + MediaQuery.of(context).padding.top),
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: DSColors.primary,
                        unselectedLabelColor: DSColors.textMuted,
                        indicatorColor: DSColors.primary,
                        indicatorWeight: 3,
                        tabs: const [
                          Tab(icon: Icon(Icons.analytics_outlined), text: 'Stats'),
                          Tab(icon: Icon(Icons.people_outline), text: 'Users'),
                          Tab(icon: Icon(Icons.storefront_outlined), text: 'Sellers'),
                          Tab(icon: Icon(Icons.verified_user_outlined), text: 'Approvals'),
                          Tab(icon: Icon(Icons.book_outlined), text: 'Catalogue'),
                          Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Orders'),
                          Tab(icon: Icon(Icons.history_edu_outlined), text: 'Activity'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildStatsTab(),
                          _buildUsersTab(),
                          _buildSellersTab(),
                          _buildApprovalsTab(),
                          _buildBooksTab(),
                          _buildOrdersTab(),
                          _buildActivityTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // ─── 1. STATS OVERVIEW TAB ───────────────────────────────────────────────────

  Widget _buildStatsTab() {
    final totalRev = _stats['totalRevenue'] ?? 0;
    final pendingBooksCount = _stats['pendingBooks'] ?? _pendingBooks.length;
    final totalProvidersCount = _stats['totalProviders'] ?? _providers.length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: DSSpacing.lg, vertical: DSSpacing.lg),
          children: [
            Text(
              'ARCHIVE SYSTEM METRICS',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
                color: DSColors.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: DSSpacing.sm),
            Text(
              'Platform Overview & Operating Statistics',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: DSColors.primary,
              ),
            ),
            const SizedBox(height: DSSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900
                    ? 3
                    : (constraints.maxWidth > 550 ? 2 : 1);
                final aspectRatio = constraints.maxWidth > 900
                    ? 2.3
                    : (constraints.maxWidth > 550 ? 2.1 : 2.8);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: DSSpacing.md,
                  crossAxisSpacing: DSSpacing.md,
                  childAspectRatio: aspectRatio,
                  children: [
                    _buildStatCard('Total Users', '${_stats['totalUsers'] ?? _users.length}', Icons.people_alt_outlined, const Color(0xFFD0E9D4)),
                    _buildStatCard('Catalog Books', '${_stats['totalBooks'] ?? _books.length}', Icons.auto_stories_outlined, const Color(0xFFD9E2D8)),
                    _buildStatCard('Pending Approvals', '$pendingBooksCount', Icons.rate_review_outlined, const Color(0xFFFEF3C7)),
                    _buildStatCard('Active Sellers', '$totalProvidersCount', Icons.storefront_outlined, const Color(0xFFE0E7FF)),
                    _buildStatCard('Total Orders', '${_stats['totalOrders'] ?? _orders.length}', Icons.receipt_long_outlined, const Color(0xFFE2E3DF)),
                    _buildStatCard('Total Revenue', '₹$totalRev', Icons.currency_rupee, const Color(0xFFFFD9DC)),
                  ],
                );
              },
            ),
            const SizedBox(height: DSSpacing.xl),
            Container(
              padding: const EdgeInsets.all(DSSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DSRadius.xl),
                border: Border.all(color: DSColors.softBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.admin_panel_settings, color: DSColors.primary),
                      const SizedBox(width: DSSpacing.sm),
                      Text(
                        'Platform Infrastructure & Policy Settings',
                        style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: DSColors.charcoal),
                      ),
                    ],
                  ),
                  const SizedBox(height: DSSpacing.md),
                  _buildSettingRow('Image Storage Architecture', 'Dual AWS S3 / Local Fallback Active'),
                  _buildSettingRow('Atomic Stock Hold Window', '15 minutes (inventory_reservations)'),
                  _buildSettingRow('Platform Conservation Fee', '₹10.00 (Fixed archive fee)'),
                  _buildSettingRow('Standard Courier Shipping', '₹49.00 (Per physical parcel)'),
                  _buildSettingRow('Payment Integration', 'Razorpay HMAC-SHA256 & COD Verified'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: DSColors.textMuted)),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: DSColors.charcoal)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: DSColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: DSColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: DSColors.primary),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DSColors.charcoal),
                ),
              ],
            ),
          ),
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: DSColors.primary, shape: BoxShape.circle)),
        ],
      ),
    );
  }

  // ─── 2. USERS MANAGEMENT TAB ─────────────────────────────────────────────────

  Widget _buildUsersTab() {
    if (_users.isEmpty) {
      return const Center(child: Text('No users registered in system.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(DSSpacing.md),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final u = _users[index];
        final email = u['email'] ?? '';
        final name = u['name'] ?? 'No Name';
        final isAdmin = u['is_admin'] == true;
        final isProvider = u['provider_enabled'] == true || u['role'] == 'provider';
        final level = u['level'] ?? 'Standard Reader';
        final userId = u['id'];

        return Container(
          margin: const EdgeInsets.only(bottom: DSSpacing.md),
          padding: const EdgeInsets.all(DSSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DSRadius.lg),
            border: Border.all(color: DSColors.softBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: DSColors.charcoal)),
                        Text(email, style: const TextStyle(fontSize: 13, color: DSColors.textMuted)),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFD0E9D4), borderRadius: BorderRadius.circular(DSRadius.sm)),
                          child: const Text('ADMIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DSColors.deepForestGreen)),
                        ),
                      if (isProvider)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(DSRadius.sm)),
                          child: const Text('SELLER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF3730A3))),
                        ),
                      if (!isAdmin && !isProvider)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(DSRadius.sm)),
                          child: const Text('READER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                        ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24, color: DSColors.softBorder),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: level,
                      decoration: const InputDecoration(
                        labelText: 'Membership Level',
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13, color: DSColors.charcoal),
                      items: const [
                        DropdownMenuItem(value: 'Standard Reader', child: Text('Standard Reader')),
                        DropdownMenuItem(value: 'Curator Level Reader', child: Text('Curator Level')),
                        DropdownMenuItem(value: 'Archivist Premium', child: Text('Archivist Premium')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          _updateUserRole(userId, val, isAdmin, providerEnabled: isProvider);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: DSSpacing.md),
                  Row(
                    children: [
                      const Text('Admin: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Switch(
                        value: isAdmin,
                        activeThumbColor: DSColors.primary,
                        onChanged: (val) {
                          _updateUserRole(userId, level, val, providerEnabled: isProvider);
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Seller: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Switch(
                        value: isProvider,
                        activeThumbColor: const Color(0xFF3730A3),
                        onChanged: (val) {
                          _updateUserRole(userId, level, isAdmin, providerEnabled: val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── 3. SELLERS & PROVIDER APPROVAL TAB ──────────────────────────────────────

  Widget _buildSellersTab() {
    if (_providers.isEmpty) {
      return const Center(child: Text('No sellers or providers registered yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(DSSpacing.md),
      itemCount: _providers.length,
      itemBuilder: (context, index) {
        final p = _providers[index];
        final providerId = p['id'] as int;
        final name = p['name'] ?? 'Provider';
        final email = p['email'] ?? '';
        final status = (p['provider_status'] ?? 'active').toString().toLowerCase();
        final listingsCount = p['listings_count'] ?? 0;
        final address = p['address'] ?? 'Bangalore Hub';

        Color badgeColor = const Color(0xFFE8F5E9);
        Color textColor = DSColors.success;
        if (status == 'pending') {
          badgeColor = const Color(0xFFFFFBEB);
          textColor = DSColors.accentTerracotta;
        } else if (status == 'suspended' || status == 'rejected') {
          badgeColor = const Color(0xFFFFEBEE);
          textColor = DSColors.error;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: DSSpacing.md),
          padding: const EdgeInsets.all(DSSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DSRadius.lg),
            border: Border.all(color: DSColors.softBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: DSColors.charcoal)),
                        Text('$email • $address', style: const TextStyle(fontSize: 12, color: DSColors.textMuted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(DSRadius.sm)),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Catalogue Volume: $listingsCount active book listings',
                style: GoogleFonts.inter(fontSize: 13, color: DSColors.charcoal),
              ),
              const Divider(height: 20, color: DSColors.softBorder),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (status != 'active')
                    ElevatedButton(
                      onPressed: () => _updateProviderStatus(providerId, 'active'),
                      style: ElevatedButton.styleFrom(backgroundColor: DSColors.deepForestGreen, foregroundColor: Colors.white),
                      child: const Text('Approve & Activate Seller'),
                    ),
                  if (status == 'active')
                    OutlinedButton(
                      onPressed: () => _updateProviderStatus(providerId, 'suspended'),
                      style: OutlinedButton.styleFrom(foregroundColor: DSColors.error, side: const BorderSide(color: Color(0xFFFECACA))),
                      child: const Text('Suspend Seller Privileges'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── 4. PENDING BOOK APPROVALS & MODERATION TAB ──────────────────────────────

  Widget _buildApprovalsTab() {
    if (_pendingBooks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(DSSpacing.xl),
          child: Text('No pending book listings requiring review.', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(DSSpacing.md),
      itemCount: _pendingBooks.length,
      itemBuilder: (context, index) {
        final b = _pendingBooks[index];
        return _PendingBookCard(
          book: b,
          onApprove: _approveBook,
          onReject: _rejectBook,
        );
      },
    );
  }

  // ─── 5. BOOK CATALOGUE MANAGEMENT TAB ────────────────────────────────────────

  Widget _buildBooksTab() {
    final filtered = _catalogSearchQuery.isEmpty
        ? _books
        : _books.where((b) {
            final t = (b['title'] ?? '').toString().toLowerCase();
            final a = (b['author'] ?? '').toString().toLowerCase();
            final q = _catalogSearchQuery.toLowerCase();
            return t.contains(q) || a.contains(q);
          }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(DSSpacing.md),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search catalog by title or author...',
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(DSRadius.md), borderSide: const BorderSide(color: DSColors.softBorder)),
            ),
            onChanged: (val) => setState(() => _catalogSearchQuery = val),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No books matching query in catalog.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: DSSpacing.md),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final b = filtered[index];
                    final title = b['title'] ?? 'Untitled';
                    final author = b['author'] ?? 'Unknown Author';
                    final category = b['category'] ?? 'General';
                    final price = b['price'] ?? 0.0;
                    final bookId = b['id'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: DSSpacing.md),
                      padding: const EdgeInsets.all(DSSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(DSRadius.lg),
                        border: Border.all(color: DSColors.softBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: DSColors.charcoal), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text('by $author', style: const TextStyle(fontSize: 13, color: DSColors.textMuted)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(DSRadius.sm)),
                                      child: Text(category, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(width: DSSpacing.sm),
                                    Text('₹$price', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: DSColors.primary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: DSColors.error),
                            tooltip: 'Moderator Delete',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Moderator Delete'),
                                  content: Text('Are you sure you want to remove "$title" from the library catalogue?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _deleteBook(bookId);
                                      },
                                      child: const Text('Delete', style: TextStyle(color: DSColors.error)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── 6. ORDERS & TRANSACTIONS MONITORING TAB ─────────────────────────────────

  Widget _buildOrdersTab() {
    if (_orders.isEmpty) {
      return const Center(child: Text('No order transactions found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(DSSpacing.md),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final o = _orders[index];
        final orderId = o['id'];
        final userEmail = o['user_email'] ?? '';
        final title = o['book_title'] ?? 'Untitled Book';
        final isPurchase = o['is_purchase'] == true;
        final rentalDays = o['rental_days'];
        final status = (o['status'] ?? 'pending').toString().toLowerCase();

        return Container(
          margin: const EdgeInsets.only(bottom: DSSpacing.md),
          padding: const EdgeInsets.all(DSSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DSRadius.lg),
            border: Border.all(color: DSColors.softBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order #$orderId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPurchase ? const Color(0xFFFFD9DC) : const Color(0xFFD0E9D4),
                      borderRadius: BorderRadius.circular(DSRadius.sm),
                    ),
                    child: Text(
                      isPurchase ? 'PURCHASE' : 'RENTAL ($rentalDays days)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isPurchase ? DSColors.error : const Color(0xFF064E3B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DSSpacing.sm),
              Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: DSColors.charcoal)),
              const SizedBox(height: 2),
              Text('Customer: $userEmail', style: const TextStyle(fontSize: 12, color: DSColors.textMuted)),
              const Divider(height: 24, color: DSColors.softBorder),
              Row(
                children: [
                  const Text('Fulfillment Status: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(width: DSSpacing.sm),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: ['pending', 'processing', 'active', 'completed', 'returned', 'cancelled', 'dispatched', 'confirmed'].contains(status)
                          ? status
                          : 'pending',
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13, color: DSColors.charcoal),
                      items: const [
                        DropdownMenuItem(value: 'pending', child: Text('Pending Payment')),
                        DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                        DropdownMenuItem(value: 'processing', child: Text('Processing')),
                        DropdownMenuItem(value: 'dispatched', child: Text('Dispatched / In-Transit')),
                        DropdownMenuItem(value: 'active', child: Text('Active (Rent / Borrow)')),
                        DropdownMenuItem(value: 'returned', child: Text('Returned')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                        DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          _updateOrderStatus(orderId, val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── 7. SYSTEM ACTIVITY LOGS TAB ─────────────────────────────────────────────

  Widget _buildActivityTab() {
    if (_activityLogs.isEmpty) {
      return const Center(child: Text('No system audit logs found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(DSSpacing.md),
      itemCount: _activityLogs.length,
      itemBuilder: (context, index) {
        final log = _activityLogs[index];
        final time = log['timestamp'] ?? '';
        final type = log['type'] ?? 'System';
        final desc = log['description'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: DSSpacing.sm),
          padding: const EdgeInsets.all(DSSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DSRadius.md),
            border: Border.all(color: DSColors.softBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: type == 'Order' ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(DSRadius.sm),
                ),
                child: Text(type, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: type == 'Order' ? const Color(0xFF1D4ED8) : const Color(0xFF15803D))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(desc, style: GoogleFonts.inter(fontSize: 13, color: DSColors.charcoal, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(time, style: GoogleFonts.inter(fontSize: 11, color: DSColors.textLight)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PendingBookCard extends StatefulWidget {
  final Map<String, dynamic> book;
  final Function(int, String) onApprove;
  final Function(int, String) onReject;
  const _PendingBookCard({
    required this.book,
    required this.onApprove,
    required this.onReject,
  });
  @override
  State<_PendingBookCard> createState() => _PendingBookCardState();
}

class _PendingBookCardState extends State<_PendingBookCard> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.book;
    final int bookId = b['id'] ?? 0;
    final title = b['title'] ?? 'Untitled';
    final author = b['author'] ?? 'Unknown Author';
    final category = b['category'] ?? 'General';
    final price = (b['price'] as num?)?.toDouble() ?? 0.0;
    final condition = b['condition'] ?? 'Good';
    final List<dynamic> images = b['images'] ?? [];
    final coverUrl = b['coverUrl'] ?? b['image_url'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: DSSpacing.md),
      padding: const EdgeInsets.all(DSSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DSRadius.lg),
        border: Border.all(color: DSColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (coverUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(DSRadius.sm),
                  child: Image.network(
                    ApiService.resolveImageUrl(coverUrl),
                    width: 50,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 50,
                      height: 70,
                      color: const Color(0xFFF0F7F4),
                      child: const Icon(Icons.book, size: 24, color: DSColors.deepForestGreen),
                    ),
                  ),
                ),
              const SizedBox(width: DSSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: DSColors.charcoal), maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text('by $author', style: const TextStyle(fontSize: 12, color: DSColors.textMuted)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(DSRadius.sm)),
                          child: Text(category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        Text('Price: ₹${price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.primary)),
                        Text('Cond: $condition', style: const TextStyle(fontSize: 12, color: DSColors.error)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (images.length > 1) ...[
            const SizedBox(height: DSSpacing.sm),
            const Text('GALLERY PHOTOS:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 4),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 30,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(DSRadius.sm),
                      image: DecorationImage(image: NetworkImage(ApiService.resolveImageUrl(images[index])), fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: DSSpacing.md),
          const Text('VERIFICATION NOTES (OPTIONAL)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DSColors.charcoal)),
          const SizedBox(height: 4),
          TextField(
            controller: _notesController,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'e.g. Verified copy in excellent condition, crisp pages...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: DSColors.warmIvory,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(DSRadius.sm), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: DSSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => widget.onReject(bookId, _notesController.text.trim()),
                style: TextButton.styleFrom(foregroundColor: DSColors.error),
                child: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => widget.onApprove(bookId, _notesController.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DSColors.deepForestGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.sm)),
                ),
                child: const Text('APPROVE & VERIFY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
