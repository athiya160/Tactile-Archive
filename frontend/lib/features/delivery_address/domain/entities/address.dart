import 'package:equatable/equatable.dart';

class Address extends Equatable {
  final String id;
  final String label; // "Home", "Work", etc.
  final String recipientName;
  final String phoneNumber;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final bool isDefault;

  const Address({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phoneNumber,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [
    id,
    label,
    recipientName,
    phoneNumber,
    street,
    city,
    state,
    zipCode,
    isDefault,
  ];
}
