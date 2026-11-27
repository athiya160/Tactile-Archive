import '../../../../core/utils/result.dart';
import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';
import '../models/address_model.dart';
import '../../../../core/services/api_service.dart';

class MockAddressRepository implements AddressRepository {
  // Mutable list so that addNewAddress persists during the app session.
  final List<Address> _addresses = [
    AddressModel(
      id: '1',
      label: 'Home',
      recipientName: ApiService.userName ?? 'Arjun Sharma',
      phoneNumber: '+91 98765 43210',
      street: 'Flat 402, Green Valley Apartments',
      city: 'New Delhi',
      state: 'Delhi',
      zipCode: '110001',
      isDefault: true,
    ),
    AddressModel(
      id: '2',
      label: 'Office',
      recipientName: ApiService.userName ?? 'Arjun Sharma',
      phoneNumber: '+91 98765 00000',
      street: 'Cyber City, Phase 3, Tower C',
      city: 'Gurugram',
      state: 'Haryana',
      zipCode: '122002',
    ),
  ];

  @override
  Future<Result<List<Address>>> getSavedAddresses() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Result.success(List.unmodifiable(_addresses));
  }

  @override
  Future<Result<void>> addNewAddress(Address address) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _addresses.add(AddressModel.fromEntity(address));
    return Result.success(null);
  }

  @override
  Future<Result<void>> editAddress(Address address) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _addresses.indexWhere((a) => a.id == address.id);
    if (index != -1) {
      _addresses[index] = AddressModel.fromEntity(address);
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> selectAddress(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // In production: call API to persist selected address.
    // In mock: selection is tracked in AddressBloc state.
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteAddress(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _addresses.removeWhere((address) => address.id == id);
    return Result.success(null);
  }
}
