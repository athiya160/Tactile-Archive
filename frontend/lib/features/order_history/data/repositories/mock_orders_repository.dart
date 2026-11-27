import '../../../../core/utils/result.dart';
import '../../../home/domain/entities/book.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_history_stats.dart';
import '../../domain/repositories/orders_repository.dart';

import '../../domain/entities/order_item.dart';

class MockOrdersRepository implements OrdersRepository {
  final List<Order> _mockOrders = [
    Order(
      id: '#ARCH-882910',
      items: const [
        OrderItem(
          id: 'item-1',
          book: Book(
            id: '1',
            title: 'The Philosophy of Silence',
            author: 'Unknown',
            coverUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuAs7lWV1mtEeyeNVlrIoiZlFYgL2PZNSdG2QDxMHxIWzh-O66hr37QE_2SOmrklZ7LgcDFJdwPb88cvO-tCQtDn5hjxkWC0a_VCsHaTxjRhd8g14zrK7B3CXKXOUqUk0VnD-VO4wYCVKDbyC7BjXdgt4hIyQqcE4uJErd40KiBfH5FJnhuHAqtVnYD9LhGH9RWwfse2zATkfeOjHpgQpzUezOzxRFIsHcUUleCybdqhiUCxJ5pf6ITeN4rt6l1z-pWtRDjKvWFG-Eky',
            categories: ['Philosophy'],
            listingType: ListingType.forSale,
            rating: 4.8,
          ),
          type: OrderType.purchase,
          price: 42.00,
        ),
      ],
      date: DateTime(2023, 10, 24),
      status: OrderStatus.completed,
      totalAmount: 42.00,
    ),
    Order(
      id: '#ARCH-990122',
      items: const [
        OrderItem(
          id: 'item-2',
          book: Book(
            id: '2',
            title: 'Ephemeral Architecture',
            author: 'Unknown',
            coverUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCboiIQyRfDF-IbBNDkMhbwbkO83lirlz4XTTbnx9y3j_-GxskbfdlaaXi2OfDY2RRUXndMPsTPBFiUIs9lEpfMQcEf_4GfIY1uDfidP4yndhFI3tQyrYrt_VnYW2xpkrkA_2jERDx8fxHXDUi_U3dGKPlS-KTanhZ2hgp7tG9iyVFkGT_TZVapx8ocTGFQFWoQXtRA3hK0kVHeVLKMLll5x-_mPu1O0qK4051VJ9uyZvpmlTL972r78lCPN-Rd6hBVeuPsXeMfmzb9',
            categories: ['Architecture'],
            listingType: ListingType.forRent,
            rating: 4.5,
          ),
          type: OrderType.rental,
          price: 8.50,
        ),
      ],
      date: DateTime(2023, 11, 02),
      status: OrderStatus.inProgress,
      totalAmount: 8.50,
    ),
    Order(
      id: '#ARCH-442001',
      items: const [
        OrderItem(
          id: 'item-3',
          book: Book(
            id: '3',
            title: 'The Great Archive Donation',
            author: 'Unknown',
            coverUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuD8RfjhZWCaqTD9LEZ4HbP-4j4XfykPLhKBFqzGQ8kvmTqMSNVKGJR6i6nD-e1scfgK3ROlwJCfder6BYiu16oFoKwC0Po9ZFBiIYsYY_IybVyR2OtJePTEpeLkmjAY63gGkobZ_EzkM3wV4Ic8q5HmQXSkP37nwi1CpjsQq3Uaa8hj-_PfBc4bpo7Duxl7MU4kapFgAeYYdhZvS95TyLytxbXn7Pw3d5AQ5DnrdEYcpFVCHXW_7P3QL3SHCc--IXLc5WEGoGPubWNg',
            categories: ['History'],
            listingType: ListingType.donate,
            rating: 4.9,
          ),
          type: OrderType.donation,
          price: 120.00,
        ),
      ],
      date: DateTime(2023, 12, 15),
      status: OrderStatus.returned,
      totalAmount: 120.00,
    ),
  ];

  @override
  Future<Result<List<Order>>> getOrders({String? filter}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (filter == 'Pending') {
      return Result.success(
        _mockOrders.where((o) => o.status == OrderStatus.inProgress).toList(),
      );
    }
    return Result.success(_mockOrders);
  }

  @override
  Future<Result<OrderHistoryStats>> getStats() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Result.success(
      const OrderHistoryStats(
        totalArchiveValue: 1248.50,
        purchaseCount: 14,
        rentalCount: 8,
      ),
    );
  }
}
