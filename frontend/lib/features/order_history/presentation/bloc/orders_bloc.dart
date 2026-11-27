import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_orders.dart';
import '../../domain/usecases/get_order_stats.dart';
import 'orders_event.dart';
import 'orders_state.dart';

export 'orders_event.dart';
export 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final GetOrders getOrders;
  final GetOrderStats getOrderStats;

  OrdersBloc({required this.getOrders, required this.getOrderStats})
    : super(const OrdersState()) {
    on<OrdersStarted>(_onStarted);
    on<OrdersFilterChanged>(_onFilterChanged);
  }

  Future<void> _onStarted(
    OrdersStarted event,
    Emitter<OrdersState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final ordersResult = await getOrders(state.selectedFilter);
    final statsResult = await getOrderStats(NoParams());

    emit(
      state.copyWith(
        isLoading: false,
        orders: ordersResult.isSuccess ? ordersResult.data ?? [] : [],
        stats: statsResult.isSuccess ? statsResult.data : null,
        error: ordersResult.isFailure ? ordersResult.failure?.message : null,
      ),
    );
  }

  Future<void> _onFilterChanged(
    OrdersFilterChanged event,
    Emitter<OrdersState> emit,
  ) async {
    if (state.selectedFilter == event.filter) return;

    emit(state.copyWith(isLoading: true, selectedFilter: event.filter));
    final result = await getOrders(event.filter);

    emit(
      state.copyWith(
        isLoading: false,
        orders: result.isSuccess ? result.data ?? [] : [],
        error: result.isFailure ? result.failure?.message : null,
      ),
    );
  }
}
