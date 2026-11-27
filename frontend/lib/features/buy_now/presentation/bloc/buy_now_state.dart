import 'package:equatable/equatable.dart';

abstract class BuyNowState extends Equatable {
  const BuyNowState();

  @override
  List<Object?> get props => [];
}

class BuyNowInitial extends BuyNowState {}

class BuyNowLoading extends BuyNowState {}

class BuyNowSuccess extends BuyNowState {}

class BuyNowError extends BuyNowState {
  final String message;
  const BuyNowError(this.message);

  @override
  List<Object?> get props => [message];
}
