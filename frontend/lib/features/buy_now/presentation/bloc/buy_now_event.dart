import 'package:equatable/equatable.dart';

abstract class BuyNowEvent extends Equatable {
  const BuyNowEvent();

  @override
  List<Object?> get props => [];
}

class BuyNowCheckoutPressed extends BuyNowEvent {
  final String? bookId;
  final String mode;
  final int? rentalDays;
  final double? rentalFee;
  final double? price;
  final String paymentMethod;
  final String shippingAddress;
  final bool paymentVerified;

  const BuyNowCheckoutPressed({
    this.bookId,
    required this.mode,
    this.rentalDays,
    this.rentalFee,
    this.price,
    required this.paymentMethod,
    required this.shippingAddress,
    this.paymentVerified = false,
  });

  @override
  List<Object?> get props => [
    bookId,
    mode,
    rentalDays,
    rentalFee,
    price,
    paymentMethod,
    shippingAddress,
    paymentVerified,
  ];
}
