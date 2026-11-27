import '../../../../core/utils/result.dart';
import '../entities/address.dart';

abstract class AddressRepository {
  Future<Result<List<Address>>> getSavedAddresses();
  Future<Result<void>> addNewAddress(Address address);
  Future<Result<void>> editAddress(Address address);
  Future<Result<void>> selectAddress(String id);
  Future<Result<void>> deleteAddress(String id);
}
