import '../../../../core/utils/result.dart';
import '../entities/address.dart';
import '../repositories/address_repository.dart';

class AddNewAddress {
  final AddressRepository repository;

  AddNewAddress(this.repository);

  Future<Result<void>> call(Address address) =>
      repository.addNewAddress(address);
}
