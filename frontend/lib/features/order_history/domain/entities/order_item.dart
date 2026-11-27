import '../../../home/domain/entities/book.dart';
import 'order.dart';

class OrderItem {
  final String id;
  final Book book;
  final OrderType type;
  final int quantity;
  final double price;

  const OrderItem({
    required this.id,
    required this.book,
    required this.type,
    this.quantity = 1,
    this.price = 0.0,
  });

  String get typeLabel {
    switch (type) {
      case OrderType.purchase:
        return 'Purchase';
      case OrderType.rental:
        return 'Rental';
      case OrderType.donation:
        return 'Donation';
      case OrderType.borrow:
        return 'Borrow';
    }
  }
}
