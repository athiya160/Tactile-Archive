import '../../../../core/usecases/usecase.dart';
import '../entities/cart.dart';
import '../repositories/cart_repository.dart';

class WatchCart implements StreamUseCase<Cart, NoParams> {
  final CartRepository repository;

  WatchCart(this.repository);

  @override
  Stream<Cart> call(NoParams params) {
    return repository.watchCart();
  }
}
