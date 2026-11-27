import '../../domain/entities/address.dart';

class AddressModel extends Address {
  const AddressModel({
    required super.id,
    required super.label,
    required super.recipientName,
    required super.phoneNumber,
    required super.street,
    required super.city,
    required super.state,
    required super.zipCode,
    super.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      recipientName: json['recipientName']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      street: json['street']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      zipCode: json['zipCode']?.toString() ?? '',
      isDefault: json['isDefault'] == true || json['isDefault'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'isDefault': isDefault,
    };
  }

  factory AddressModel.fromEntity(Address entity) {
    return AddressModel(
      id: entity.id,
      label: entity.label,
      recipientName: entity.recipientName,
      phoneNumber: entity.phoneNumber,
      street: entity.street,
      city: entity.city,
      state: entity.state,
      zipCode: entity.zipCode,
      isDefault: entity.isDefault,
    );
  }
}
