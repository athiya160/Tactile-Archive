import 'package:equatable/equatable.dart';
import '../../domain/entities/address.dart';

enum AddressStatus { initial, loading, success, confirmed, failure }

class AddressState extends Equatable {
  final AddressStatus status;
  final List<Address> addresses;
  final String? selectedAddressId;
  final String? errorMessage;

  const AddressState({
    this.status = AddressStatus.initial,
    this.addresses = const [],
    this.selectedAddressId,
    this.errorMessage,
  });

  AddressState copyWith({
    AddressStatus? status,
    List<Address>? addresses,
    String? selectedAddressId,
    String? errorMessage,
  }) {
    return AddressState(
      status: status ?? this.status,
      addresses: addresses ?? this.addresses,
      selectedAddressId: selectedAddressId ?? this.selectedAddressId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    addresses,
    selectedAddressId,
    errorMessage,
  ];
}
