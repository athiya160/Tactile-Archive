import 'package:equatable/equatable.dart';

class SettingsEntity extends Equatable {
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String bio;
  final String avatarUrl;
  final Map<String, bool> notifications;

  const SettingsEntity({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.bio,
    required this.avatarUrl,
    required this.notifications,
  });

  SettingsEntity copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? bio,
    String? avatarUrl,
    Map<String, bool>? notifications,
  }) {
    return SettingsEntity(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      notifications: notifications ?? this.notifications,
    );
  }

  @override
  List<Object?> get props => [
    fullName,
    email,
    phone,
    address,
    bio,
    avatarUrl,
    notifications,
  ];
}
