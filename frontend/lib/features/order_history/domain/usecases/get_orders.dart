import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/order.dart';
import '../repositories/orders_repository.dart';

class GetOrders implements UseCase<List<Order>, String?> {
  final OrdersRepository repository;

  GetOrders(this.repository);

  @override
  Future<Result<List<Order>>> call(String? params) async {
    return await repository.getOrders(filter: params);
  }
}
