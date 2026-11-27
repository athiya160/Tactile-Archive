import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/cart_repository.dart';

class SetCartDeliveryAddress
    implements UseCase<void, SetCartDeliveryAddressParams> {
  final CartRepository repository;

  SetCartDeliveryAddress(this.repository);

  @override
  Future<Result<void>> call(SetCartDeliveryAddressParams params) async {
    return await repository.setDeliveryAddress(
      params.address,
      params.recipient,
    );
  }
}

class SetCartDeliveryAddressParams {
  final String address;
  final String recipient;

  SetCartDeliveryAddressParams({
    required this.address,
    required this.recipient,
  });
}
