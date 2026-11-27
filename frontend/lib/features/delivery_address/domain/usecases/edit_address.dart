import '../../../../core/utils/result.dart';
import '../entities/address.dart';
import '../repositories/address_repository.dart';

class EditAddress {
  final AddressRepository repository;

  EditAddress(this.repository);

  Future<Result<void>> call(Address address) => repository.editAddress(address);
}
