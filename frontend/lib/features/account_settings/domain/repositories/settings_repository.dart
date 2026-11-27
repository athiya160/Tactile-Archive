import '../entities/settings_entity.dart';

abstract class SettingsRepository {
  Future<SettingsEntity> getSettings();

  Future<void> updateSettings(SettingsEntity settings);

  Future<void> changePassword(String currentPassword, String newPassword, String confirmPassword);

  Future<String> uploadAvatar(String imagePath);
}
