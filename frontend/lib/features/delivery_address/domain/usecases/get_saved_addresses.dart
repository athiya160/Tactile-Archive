import '../../../../core/utils/result.dart';
import '../entities/address.dart';
import '../repositories/address_repository.dart';

class GetSavedAddresses {
  final AddressRepository repository;

  GetSavedAddresses(this.repository);

  Future<Result<List<Address>>> call() => repository.getSavedAddresses();
}
