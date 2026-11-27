import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/cart_repository.dart';

class UpdateCartItemQuantity
    implements UseCase<void, UpdateCartItemQuantityParams> {
  final CartRepository repository;

  UpdateCartItemQuantity(this.repository);

  @override
  Future<Result<void>> call(UpdateCartItemQuantityParams params) async {
    return await repository.updateItemQuantity(params.itemId, params.quantity);
  }
}

class UpdateCartItemQuantityParams {
  final String itemId;
  final int quantity;

  const UpdateCartItemQuantityParams({
    required this.itemId,
    required this.quantity,
  });
}
