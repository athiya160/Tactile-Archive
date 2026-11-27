import 'package:equatable/equatable.dart';
import '../../domain/entities/address.dart';

abstract class AddressEvent extends Equatable {
  const AddressEvent();

  @override
  List<Object?> get props => [];
}

class AddressStarted extends AddressEvent {}

class AddressSelected extends AddressEvent {
  final String id;
  const AddressSelected(this.id);

  @override
  List<Object?> get props => [id];
}

class AddAddressPressed extends AddressEvent {
  final Address address;
  const AddAddressPressed(this.address);

  @override
  List<Object?> get props => [address];
}

class ConfirmAddressPressed extends AddressEvent {}

class AddressDeletePressed extends AddressEvent {
  final String id;
  const AddressDeletePressed(this.id);

  @override
  List<Object?> get props => [id];
}

class EditAddressPressed extends AddressEvent {
  final Address address;
  const EditAddressPressed(this.address);

  @override
  List<Object?> get props => [address];
}
