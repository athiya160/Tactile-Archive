import '../../../../core/utils/result.dart';
import '../repositories/address_repository.dart';

class DeleteAddress {
  final AddressRepository repository;

  DeleteAddress(this.repository);

  Future<Result<void>> call(String id) async {
    return await repository.deleteAddress(id);
  }
}
