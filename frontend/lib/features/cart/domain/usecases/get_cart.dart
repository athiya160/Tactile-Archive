import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/cart.dart';
import '../repositories/cart_repository.dart';

class GetCart implements UseCase<Cart, NoParams> {
  final CartRepository repository;

  GetCart(this.repository);

  @override
  Future<Result<Cart>> call(NoParams params) async {
    return await repository.getCart();
  }
}
