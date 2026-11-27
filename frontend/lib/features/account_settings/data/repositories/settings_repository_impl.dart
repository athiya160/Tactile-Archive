import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../../../core/services/api_service.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  // Mock data representing the user profile from design
  SettingsEntity _settings = SettingsEntity(
    fullName: ApiService.userName ?? 'Athiya Tabassum',
    email: 'athiya160@gmail.com',
    phone: '+91 99864 74220',
    address: 'Bangalore, Karnataka, India',
    bio:
        'Bibliophile, avid reader and community member.',
    avatarUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuApGcaPh2fmSsLKG905vrDuDzJaCH5-I2DqiwfHO1dq3nuGi4gxX18UvztP-yKTMgJTQqWpebVCIzkn1G1MhHfT4IYKGAiP4_EM8951blzQji_9pGojPZD1OSMN3AEQ4hS-pkZ1tDn1R_qSCcOvtBUgwqbhKfH2NlJca49VS_DAQmH17HNdaK4zLyebo-9h4kfIfwZ4fN_P4u9X0cN9Awpqz0fdzR05hoybXfilgK6779TNVRPkyIetPsSxCJiMgFPbqVjZ4wp6hoK0',
    notifications: {
      'Rent Request': true,
      'Purchase Request': true,
      'New Book Arrival': false,
      'Book Due Reminders': true,
    },
  );

  @override
  Future<SettingsEntity> getSettings() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _settings;
  }

  @override
  Future<void> updateSettings(SettingsEntity settings) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    _settings = settings;
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (newPassword != confirmPassword) {
      throw Exception('Passwords do not match');
    }
  }

  @override
  Future<String> uploadAvatar(String imagePath) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return imagePath;
  }
}
