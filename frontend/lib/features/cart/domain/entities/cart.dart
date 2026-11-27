import 'package:equatable/equatable.dart';
import 'cart_item.dart';

class Cart extends Equatable {
  final List<CartItem> items;
  final String? deliveryAddress;
  final String? recipientName;
  final double archiveFee;
  final double shippingFee;

  const Cart({
    this.items = const [],
    this.deliveryAddress,
    this.recipientName,
    this.archiveFee = 1.20,
    this.shippingFee = 0.0,
  });

  double get subtotal =>
      items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  double get total => subtotal + archiveFee + shippingFee;

  /// Cart subtotal represented in integer paise
  int get subtotalPaise =>
      items.fold<int>(0, (sum, item) => sum + item.totalItemPaise);

  /// Archive/Platform fee represented in integer paise (default: 120 paise = ₹1.20)
  int get archiveFeePaise => (archiveFee * 100).round();

  /// Shipping fee represented in integer paise (default: 0 paise = FREE)
  int get shippingFeePaise => (shippingFee * 100).round();

  /// Total cart amount represented in integer paise
  int get totalPaise => subtotalPaise + archiveFeePaise + shippingFeePaise;

  @override
  List<Object?> get props => [
    items,
    deliveryAddress,
    recipientName,
    archiveFee,
    shippingFee,
  ];

  Cart copyWith({
    List<CartItem>? items,
    String? deliveryAddress,
    String? recipientName,
    double? archiveFee,
    double? shippingFee,
  }) {
    return Cart(
      items: items ?? this.items,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      recipientName: recipientName ?? this.recipientName,
      archiveFee: archiveFee ?? this.archiveFee,
      shippingFee: shippingFee ?? this.shippingFee,
    );
  }
}
