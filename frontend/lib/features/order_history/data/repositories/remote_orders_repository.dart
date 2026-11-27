import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../../../home/domain/entities/book.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_history_stats.dart';
import '../../domain/repositories/orders_repository.dart';

import '../../domain/entities/order_item.dart';
import 'mock_orders_repository.dart';

class RemoteOrdersRepository implements OrdersRepository {
  final ApiClient apiClient;
  final MockOrdersRepository _fallback = MockOrdersRepository();

  RemoteOrdersRepository(this.apiClient);

  @override
  Future<Result<List<Order>>> getOrders({String? filter}) async {
    try {
      final response = await apiClient.getJson(
        '/orders',
        queryParameters: filter != null ? {'filter': filter} : null,
      );
      if (response is List) {
        final orders = response.map((item) {
          final data = item as Map<String, dynamic>;
          final itemsList = (data['items'] as List?)?.map((i) {
            final itemData = i as Map<String, dynamic>;
            return OrderItem(
              id: itemData['id']?.toString() ?? '',
              book: _parseBook(itemData['book']),
              type: _parseOrderType(itemData['type']),
              quantity: itemData['quantity'] is int ? itemData['quantity'] as int : 1,
              price: _parseDouble(itemData['price']) ?? 0.0,
            );
          }).toList() ?? [];

          return Order(
            id: data['id']?.toString() ?? '',
            date: DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now(),
            status: _parseOrderStatus(data['status']),
            totalAmount: _parseDouble(data['total_amount']) ?? 0.0,
            deliveryAddress: data['delivery_address']?.toString(),
            paymentMethod: data['payment_method']?.toString(),
            paymentStatus: data['payment_status']?.toString(),
            items: itemsList,
            trackingId: data['tracking_id']?.toString(),
            carrier: data['carrier']?.toString(),
            estimatedDelivery: data['estimated_delivery']?.toString(),
            shippingStatus: data['shipping_status']?.toString() ?? 'pending',
          );
        }).toList();
        if (orders.isNotEmpty) {
          return Result.success(orders);
        }
      }
    } catch (_) {
      // Fallback to mock orders when server is offline
    }
    return _fallback.getOrders(filter: filter);
  }

  @override
  Future<Result<OrderHistoryStats>> getStats() async {
    try {
      final response = await apiClient.getJson('/orders/stats');
      if (response is Map<String, dynamic>) {
        return Result.success(
          OrderHistoryStats(
            totalArchiveValue:
                _parseDouble(response['totalArchiveValue']) ?? 0.0,
            purchaseCount: response['purchaseCount'] is int
                ? response['purchaseCount'] as int
                : 0,
            rentalCount: response['rentalCount'] is int
                ? response['rentalCount'] as int
                : 0,
          ),
        );
      }
    } catch (_) {
      // Fallback to mock stats when server is offline
    }
    return _fallback.getStats();
  }

  Book _parseBook(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      throw const ServerFailure('Invalid book data in order');
    }
    return Book(
      id: raw['id']?.toString() ?? '',
      title: raw['title']?.toString() ?? '',
      author: raw['author']?.toString() ?? '',
      coverUrl: raw['coverUrl']?.toString() ?? '',
      categories: List<String>.from(raw['categories'] ?? <String>[]),
      listingType: _parseListingType(raw['listingType']),
      rating: _parseDouble(raw['rating']) ?? 0.0,
      price: _parseDouble(raw['price']) ?? 0.0,
      originalPrice: _parseDouble(raw['originalPrice']),
      discountPercentage: _parseDouble(raw['discountPercentage']),
      isStaffPick: raw['isStaffPick'] == true,
      isFavorite: raw['isFavorite'] == true,
      description: raw['description']?.toString() ?? '',
      edition: raw['edition']?.toString(),
      pages: raw['pages']?.toString(),
      publisher: raw['publisher']?.toString() ?? '',
      language: raw['language']?.toString() ?? '',
      isbn: raw['isbn']?.toString() ?? '',
      category: raw['category']?.toString() ?? 'Fiction',
      quote: raw['quote']?.toString(),
      quoteAuthor: raw['quoteAuthor']?.toString(),
    );
  }

  ListingType _parseListingType(dynamic raw) {
    final value = raw?.toString().toLowerCase();
    switch (value) {
      case 'forrent':
      case 'for_rent':
      case 'for rent':
        return ListingType.forRent;
      case 'forsale':
      case 'for_sale':
      case 'for sale':
        return ListingType.forSale;
      case 'donate':
      case 'donation':
        return ListingType.donate;
      default:
        return ListingType.forSale;
    }
  }

  OrderType _parseOrderType(dynamic raw) {
    final value = raw?.toString().toLowerCase();
    switch (value) {
      case 'purchase':
        return OrderType.purchase;
      case 'rental':
        return OrderType.rental;
      case 'donation':
        return OrderType.donation;
      case 'borrow':
        return OrderType.borrow;
      default:
        return OrderType.purchase;
    }
  }

  OrderStatus _parseOrderStatus(dynamic raw) {
    final value = raw?.toString().toLowerCase();
    switch (value) {
      case 'completed':
        return OrderStatus.completed;
      case 'inprogress':
      case 'in_progress':
      case 'in progress':
        return OrderStatus.inProgress;
      case 'returned':
        return OrderStatus.returned;
      default:
        return OrderStatus.completed;
    }
  }

  double? _parseDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }
}
