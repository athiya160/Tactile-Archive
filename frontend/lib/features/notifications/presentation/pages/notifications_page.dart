import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/design_system/tokens/ds_colors.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _activeFilter = 'all'; // all, unread, action

  // Mock initial state combined with live notifications
  final List<Map<String, dynamic>> _sampleNotifications = [
    {
      'id': 101,
      'channel': 'customer',
      'category': 'exchange',
      'icon': '🔄',
      'title': 'Exchange Scheduled Tomorrow at 5:00 PM',
      'message': 'Your verified physical exchange for "Atomic Habits" is confirmed at Tactile Hub Indiranagar (0.8 km).',
      'time': '10m ago',
      'is_read': false,
      'action_label': 'View Exchange QR',
      'action_route': '/exchange-map',
    },
    {
      'id': 102,
      'channel': 'customer',
      'category': 'pickup',
      'icon': '📦',
      'title': 'Book Ready for Pickup',
      'message': '"Designing Data-Intensive Applications" is packed and ready at Koramangala Hub safe shelf #12.',
      'time': '1h ago',
      'is_read': false,
      'action_label': 'View Pickup Code',
      'action_route': '/order-history',
    },
    {
      'id': 103,
      'channel': 'customer',
      'category': 'study',
      'icon': '🎓',
      'title': 'AI Study Plan Rebalanced',
      'message': 'AI detected a 2-day study lag on CS503 Operating Systems. 1-tap rebalance adjusted your daily pace to 2.5 hrs/day.',
      'time': '3h ago',
      'is_read': false,
      'action_label': 'View Study Plan',
      'action_route': '/student-dashboard',
    },
    {
      'id': 104,
      'channel': 'provider',
      'category': 'request',
      'icon': '📥',
      'title': 'New Rental Request Received',
      'message': 'Rahul M. requested to rent "Clean Architecture" for 14 days (₹120 earnings after escrow).',
      'time': '4h ago',
      'is_read': false,
      'action_label': 'Review in Provider Hub',
      'action_route': '/profile',
    },
    {
      'id': 105,
      'channel': 'customer',
      'category': 'gamification',
      'icon': '🏆',
      'title': '⭐ Trusted Reader Badge Unlocked!',
      'message': 'Congratulations! You completed 8 verified community exchanges and earned the Trusted Reader passport seal.',
      'time': '1d ago',
      'is_read': true,
      'action_label': 'View Passport',
      'action_route': '/profile',
    },
    {
      'id': 106,
      'channel': 'customer',
      'category': 'order',
      'icon': '🚚',
      'title': 'Order Dispatched #LF-8921',
      'message': 'Your package containing 2 curated books is out for standard carbon-neutral delivery.',
      'time': '2d ago',
      'is_read': true,
      'action_label': 'Track Order',
      'action_route': '/order-history',
    },
    {
      'id': 107,
      'channel': 'provider',
      'category': 'inventory',
      'icon': '📈',
      'title': 'Weekly Provider Payout Settled',
      'message': '₹1,450 has been settled to your linked UPI account for 5 completed rentals this week.',
      'time': '3d ago',
      'is_read': true,
      'action_label': 'View Payouts',
      'action_route': '/profile',
    },
  ];

  late List<Map<String, dynamic>> _notifications;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _notifications = List.from(_sampleNotifications);
    _fetchLiveNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveNotifications() async {
    try {
      final res = await ApiService.get('/notifications');
      if (res.statusCode == 200 && res.data is List) {
        final liveItems = (res.data as List).map((e) => {
          'id': e['id'] ?? DateTime.now().millisecondsSinceEpoch,
          'channel': 'customer',
          'category': 'general',
          'icon': '🔔',
          'title': e['title'] ?? 'Notification',
          'message': e['message'] ?? '',
          'time': 'Just now',
          'is_read': e['is_read'] == true,
          'action_label': null,
          'action_route': null,
        }).toList();

        if (mounted && liveItems.isNotEmpty) {
          setState(() {
            _notifications.insertAll(0, liveItems);
          });
        }
      }
    } catch (_) {}
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n['is_read'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read.')),
    );
  }

  void _markSingleAsRead(int id) {
    setState(() {
      final idx = _notifications.indexWhere((n) => n['id'] == id);
      if (idx != -1) {
        _notifications[idx]['is_read'] = true;
      }
    });
  }

  List<Map<String, dynamic>> _getFilteredList(String channel) {
    return _notifications.where((n) {
      if (n['channel'] != channel) return false;
      if (_activeFilter == 'unread') return n['is_read'] == false;
      if (_activeFilter == 'action') return n['action_label'] != null;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['is_read']).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F6),
      appBar: AppBar(
        backgroundColor: DSColors.forestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Notification Center',
          style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark All Read',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFFDE68A)),
              ),
            ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD69E2E),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_outline, size: 16),
                  const SizedBox(width: 6),
                  const Text('Customer Hub'),
                  const SizedBox(width: 6),
                  _buildTabBadge('customer'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storefront_outlined, size: 16),
                  const SizedBox(width: 6),
                  const Text('Provider Hub'),
                  const SizedBox(width: 6),
                  _buildTabBadge('provider'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // Filter Chips Bar
              _buildFilterChips(),

              // Notifications List
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNotificationList('customer'),
                    _buildNotificationList('provider'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBadge(String channel) {
    final count = _notifications.where((n) => n['channel'] == channel && !n['is_read']).length;
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFD69E2E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E)),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Unread', 'unread'),
          const SizedBox(width: 8),
          _buildFilterChip('Action Required', 'action'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _activeFilter == value;
    return InkWell(
      onTap: () => setState(() => _activeFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D3B2E) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF4A5568),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList(String channel) {
    final items = _getFilteredList(channel);

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D3B2E).withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_none, size: 48, color: Color(0xFF0D3B2E)),
              ),
              const SizedBox(height: 16),
              Text(
                'No notifications here',
                style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E)),
              ),
              const SizedBox(height: 6),
              Text(
                'You are completely caught up on your ${channel == 'customer' ? 'reading' : 'provider'} alerts!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF718096)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isRead = item['is_read'] == true;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : const Color(0xFFF7FAF7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead ? const Color(0xFFE2E8F0) : const Color(0xFFC6F6D5),
              width: isRead ? 1 : 1.5,
            ),
            boxShadow: [
              if (!isRead)
                BoxShadow(
                  color: const Color(0xFF0D3B2E).withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Icon Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7F4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC6F6D5)),
                    ),
                    child: Center(
                      child: Text(
                        item['icon'] ?? '🔔',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item['title'] ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                  color: const Color(0xFF0D3B2E),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item['time'] ?? '',
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA0AEC0)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['message'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF4A5568),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Action Buttons Row
              if (item['action_label'] != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isRead)
                      TextButton(
                        onPressed: () => _markSingleAsRead(item['id'] as int),
                        child: Text(
                          'Dismiss',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF718096)),
                        ),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _markSingleAsRead(item['id'] as int);
                        final route = item['action_route'] as String?;
                        if (route != null) {
                          context.push(route);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D3B2E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        item['action_label'] as String,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

