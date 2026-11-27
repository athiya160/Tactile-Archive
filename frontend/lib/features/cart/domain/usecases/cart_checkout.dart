import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/cart_repository.dart';

class CartCheckout implements UseCase<void, NoParams> {
  final CartRepository repository;

  CartCheckout(this.repository);

  @override
  Future<Result<void>> call(NoParams params) async {
    return await repository.checkout();
  }
}
