import '../../../../core/utils/result.dart';
import '../repositories/address_repository.dart';

class SelectAddress {
  final AddressRepository repository;

  SelectAddress(this.repository);

  Future<Result<void>> call(String id) => repository.selectAddress(id);
}
