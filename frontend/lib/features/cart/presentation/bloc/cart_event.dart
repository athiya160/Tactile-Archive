import 'package:equatable/equatable.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class CartStarted extends CartEvent {}

class CartRemovePressed extends CartEvent {
  final String itemId;
  const CartRemovePressed(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

class CartChangeAddressPressed extends CartEvent {}

class CartCheckoutPressed extends CartEvent {}

class CartItemQuantityIncreased extends CartEvent {
  final String itemId;
  const CartItemQuantityIncreased(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

class CartItemQuantityDecreased extends CartEvent {
  final String itemId;
  const CartItemQuantityDecreased(this.itemId);

  @override
  List<Object?> get props => [itemId];
}
