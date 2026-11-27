
import 'order_item.dart';

enum OrderType { purchase, rental, donation, borrow }

enum OrderStatus { completed, inProgress, returned, cancelled }

class Order {
  final String id;
  final DateTime date;
  final OrderStatus status;
  final double totalAmount;
  final String? deliveryAddress;
  final String? paymentMethod;
  final String? paymentStatus;
  final List<OrderItem> items;

  // Tracking additions
  final String? trackingId;
  final String? carrier;
  final String? estimatedDelivery;
  final String shippingStatus;

  const Order({
    required this.id,
    required this.date,
    required this.status,
    required this.totalAmount,
    this.deliveryAddress,
    this.paymentMethod,
    this.paymentStatus,
    required this.items,
    this.trackingId,
    this.carrier,
    this.estimatedDelivery,
    this.shippingStatus = 'pending',
  });

  String get statusLabel {
    switch (status) {
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.inProgress:
        return 'In Progress';
      case OrderStatus.returned:
        return 'Returned';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}
