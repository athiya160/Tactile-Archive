import 'package:equatable/equatable.dart';

abstract class OrdersEvent extends Equatable {
  const OrdersEvent();
  @override
  List<Object?> get props => [];
}

class OrdersStarted extends OrdersEvent {
  const OrdersStarted();
}

class OrdersFilterChanged extends OrdersEvent {
  final String filter;
  const OrdersFilterChanged(this.filter);
  @override
  List<Object?> get props => [filter];
}
