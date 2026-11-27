import 'package:equatable/equatable.dart';

abstract class BookDetailsEvent extends Equatable {
  const BookDetailsEvent();

  @override
  List<Object?> get props => [];
}

class BookDetailsStarted extends BookDetailsEvent {
  final String id;
  const BookDetailsStarted(this.id);

  @override
  List<Object?> get props => [id];
}

class BookDetailsFavoriteToggled extends BookDetailsEvent {}

class BookDetailsAddToCartPressed extends BookDetailsEvent {
  final bool isPurchase;
  const BookDetailsAddToCartPressed({this.isPurchase = true});

  @override
  List<Object?> get props => [isPurchase];
}

class BookDetailsBorrowPressed extends BookDetailsEvent {
  final int durationDays;
  final String message;
  const BookDetailsBorrowPressed({this.durationDays = 14, this.message = ''});

  @override
  List<Object?> get props => [durationDays, message];
}

class BookDetailsRentPressed extends BookDetailsEvent {}
