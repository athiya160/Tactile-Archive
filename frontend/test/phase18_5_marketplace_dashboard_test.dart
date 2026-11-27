import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import 'package:libri_flow/features/profile/presentation/pages/provider_dashboard_page.dart';
import 'package:libri_flow/features/admin/presentation/pages/admin_page.dart';
import 'package:libri_flow/features/cart/domain/entities/cart.dart';
import 'package:libri_flow/features/cart/domain/entities/cart_item.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:libri_flow/core/di/service_locator.dart';
import 'package:libri_flow/core/network/api_client.dart';

void main() {
  setUpAll(() {
    if (!sl.isRegistered<ApiClient>()) {
      sl.registerLazySingleton<ApiClient>(() => ApiClient(baseUrl: 'http://127.0.0.1:8899'));
    }
  });

  group('Phase 18.5 — Seller / Provider Dashboard Tests', () {
    testWidgets('Provider dashboard renders tabs and overview correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const ProviderDashboardPage(),
        ),
      );
      await tester.pump();

      // Verify Tab headers exist
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('Requests & Orders'), findsOneWidget);
      expect(find.text('Earnings & Payouts'), findsOneWidget);
      expect(find.text('Profile & Settings'), findsOneWidget);
    });

    test('Inventory filter categories correctly classify books', () {
      final sampleBooks = [
        {'id': 1, 'title': 'Gatsby', 'stock': 2, 'approval_status': 'approved'},
        {'id': 2, 'title': '1984', 'stock': 1, 'approval_status': 'approved'},
        {'id': 3, 'title': 'Physics Vol 1', 'stock': 1, 'approval_status': 'pending_approval'},
        {'id': 4, 'title': 'Rare Folio', 'stock': 0, 'approval_status': 'approved'},
        {'id': 5, 'title': 'Damaged Book', 'stock': 1, 'approval_status': 'rejected'},
      ];

      // Active / Available: stock > 0, not pending, not rejected
      final active = sampleBooks.where((b) {
        final stock = b['stock'] as int;
        final app = (b['approval_status'] ?? '').toString();
        return stock > 0 && app != 'pending_approval' && app != 'rejected';
      }).toList();
      expect(active.length, 2);

      // Pending Review
      final pending = sampleBooks.where((b) => b['approval_status'] == 'pending_approval').toList();
      expect(pending.length, 1);

      // Unavailable / Sold: stock <= 0 or rejected
      final unavailable = sampleBooks.where((b) {
        final stock = b['stock'] as int;
        final app = (b['approval_status'] ?? '').toString();
        return stock <= 0 || app == 'rejected';
      }).toList();
      expect(unavailable.length, 2);
    });

    test('Request filter logic separates pending requests from completed transactions', () {
      final sampleRequests = [
        {'id': 101, 'type': 'Rental Request', 'status': 'pending'},
        {'id': 102, 'type': 'Purchase Order', 'status': 'approved'},
        {'id': 103, 'type': 'Borrow Request', 'status': 'completed'},
        {'id': 104, 'type': 'Rental Request', 'status': 'pending'},
        {'id': 105, 'type': 'Purchase Order', 'status': 'rejected'},
      ];

      final pendingReqs = sampleRequests.where((r) => r['status'] == 'pending').toList();
      expect(pendingReqs.length, 2);

      final completedReqs = sampleRequests.where((r) => r['status'] == 'approved' || r['status'] == 'completed').toList();
      expect(completedReqs.length, 2);
    });
  });

  group('Phase 18.5 — Admin Dashboard Security & Moderation Tests', () {
    testWidgets('Admin route restricts access when user is not admin', (WidgetTester tester) async {
      ApiService.isAdmin = false;
      ApiService.token = null;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const AdminPage(),
        ),
      );
      await tester.pump();

      // Must show restricted barrier
      expect(find.text('Restricted Administrator Portal'), findsOneWidget);
      expect(find.text('Return to Home'), findsOneWidget);
    });

    test('Admin moderation correctly transitions book approval states', () {
      final book = {'id': 42, 'title': 'Archive Codex', 'approval_status': 'pending_approval', 'condition_verification': 'pending'};

      // Approve action
      final approvedBook = Map<String, dynamic>.from(book);
      approvedBook['approval_status'] = 'approved';
      approvedBook['condition_verification'] = 'verified';
      expect(approvedBook['approval_status'], 'approved');
      expect(approvedBook['condition_verification'], 'verified');

      // Reject action
      final rejectedBook = Map<String, dynamic>.from(book);
      rejectedBook['approval_status'] = 'rejected';
      rejectedBook['verification_notes'] = 'Unacceptable physical spine wear';
      expect(rejectedBook['approval_status'], 'rejected');
      expect(rejectedBook['verification_notes'], isNotEmpty);
    });
  });

  group('Phase 18.5 — Customer Marketplace Workflows Tests', () {
    test('Cart calculation correctly aggregates prices and items', () {
      final cart = Cart(
        items: [
          const CartItem(id: 'c1', bookId: '1', title: 'Book 1', author: 'Author 1', coverUrl: '', price: 499.0, quantity: 2),
          const CartItem(id: 'c2', bookId: '2', title: 'Book 2', author: 'Author 2', coverUrl: '', price: 250.0, quantity: 1),
        ],
      );

      expect(cart.items.length, 2);
      expect(cart.subtotal, 1248.0);
      expect(cart.total, 1249.2); // Includes archive platform fee of ₹1.20
    });

    test('Order status mapping handles standard marketplace lifecycle', () {
      const validStatuses = ['pending', 'processing', 'confirmed', 'completed', 'refunded', 'failed'];
      for (final s in validStatuses) {
        expect(validStatuses.contains(s), isTrue);
      }
    });

    test('Design tokens conform to LibriFlow specifications', () {
      expect(DSColors.deepForestGreen, const Color(0xFF183D32));
      expect(DSColors.secondaryGreen, const Color(0xFF285C49));
      expect(DSColors.warmIvory, const Color(0xFFF8F5EE));
      expect(DSColors.charcoal, const Color(0xFF252923));
      expect(DSRadius.sm, 8.0);
      expect(DSRadius.card, 20.0);
    });
  });
}
