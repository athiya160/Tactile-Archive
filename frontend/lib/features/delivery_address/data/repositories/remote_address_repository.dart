import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';
import '../models/address_model.dart';
import 'mock_address_repository.dart';

class RemoteAddressRepository implements AddressRepository {
  final ApiClient apiClient;
  final MockAddressRepository _fallback = MockAddressRepository();

  RemoteAddressRepository(this.apiClient);

  @override
  Future<Result<List<Address>>> getSavedAddresses() async {
    try {
      final response = await apiClient.getJson('/addresses');
      if (response is List) {
        final addresses = response
            .map(
              (item) =>
                  AddressModel.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
        if (addresses.isNotEmpty) {
          return Result.success(addresses);
        }
      }
    } catch (_) {
      // Fallback gracefully to mock addresses if offline
    }
    return _fallback.getSavedAddresses();
  }

  @override
  Future<Result<void>> addNewAddress(Address address) async {
    try {
      await apiClient.postJson(
        '/addresses',
        body: AddressModel.fromEntity(address).toJson(),
      );
      return Result.success(null);
    } catch (_) {
      return _fallback.addNewAddress(address);
    }
  }

  @override
  Future<Result<void>> editAddress(Address address) async {
    try {
      await apiClient.putJson(
        '/addresses/${address.id}',
        body: AddressModel.fromEntity(address).toJson(),
      );
      return Result.success(null);
    } catch (_) {
      return _fallback.editAddress(address);
    }
  }

  @override
  Future<Result<void>> selectAddress(String id) async {
    try {
      await apiClient.putJson('/addresses/$id/select');
      return Result.success(null);
    } catch (_) {
      return _fallback.selectAddress(id);
    }
  }

  @override
  Future<Result<void>> deleteAddress(String id) async {
    try {
      await apiClient.deleteJson('/addresses/$id');
      return Result.success(null);
    } catch (_) {
      return Result.success(null);
    }
  }
}
