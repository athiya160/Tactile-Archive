import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/order_history_stats.dart';
import '../repositories/orders_repository.dart';

class GetOrderStats implements UseCase<OrderHistoryStats, NoParams> {
  final OrdersRepository repository;

  GetOrderStats(this.repository);

  @override
  Future<Result<OrderHistoryStats>> call(NoParams params) async {
    return await repository.getStats();
  }
}
