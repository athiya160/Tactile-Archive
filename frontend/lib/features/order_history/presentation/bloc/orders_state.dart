import 'package:equatable/equatable.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_history_stats.dart';

class OrdersState extends Equatable {
  final List<Order> orders;
  final OrderHistoryStats? stats;
  final bool isLoading;
  final String? error;
  final String selectedFilter;

  const OrdersState({
    this.orders = const [],
    this.stats,
    this.isLoading = false,
    this.error,
    this.selectedFilter = 'All History',
  });

  OrdersState copyWith({
    List<Order>? orders,
    OrderHistoryStats? stats,
    bool? isLoading,
    String? error,
    String? selectedFilter,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }

  @override
  List<Object?> get props => [orders, stats, isLoading, error, selectedFilter];
}
