import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/cart_repository.dart';

class RemoveCartItem implements UseCase<void, String> {
  final CartRepository repository;

  RemoveCartItem(this.repository);

  @override
  Future<Result<void>> call(String id) async {
    return await repository.removeItem(id);
  }
}
