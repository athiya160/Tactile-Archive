import '../../../../core/utils/result.dart';

import '../entities/order.dart';

import '../entities/order_history_stats.dart';

abstract class OrdersRepository {
  Future<Result<List<Order>>> getOrders({String? filter});

  Future<Result<OrderHistoryStats>> getStats();
}
