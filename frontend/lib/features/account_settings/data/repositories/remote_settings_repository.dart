import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';

class RemoteSettingsRepository implements SettingsRepository {
  final ApiClient apiClient;

  RemoteSettingsRepository(this.apiClient);

  static const _defaultNotifications = {
    'Rent Request': true,
    'Purchase Request': true,
    'New Book Arrival': false,
    'Book Due Reminders': true,
  };

  @override
  Future<SettingsEntity> getSettings() async {
    try {
      final response = await apiClient.getJson('/settings');
      if (response is Map<String, dynamic>) {
        final notificationsMap = <String, bool>{};
        if (response['notifications'] is Map) {
          (response['notifications'] as Map).forEach((key, value) {
            notificationsMap[key.toString()] = value == true;
          });
        }
        final entity = SettingsEntity(
          fullName: response['fullName']?.toString() ?? '',
          email: response['email']?.toString() ?? '',
          phone: response['phone']?.toString() ?? '',
          address: response['address']?.toString() ?? '',
          bio: response['bio']?.toString() ?? '',
          avatarUrl: response['avatarUrl']?.toString() ?? '',
          notifications: notificationsMap.isNotEmpty ? notificationsMap : _defaultNotifications,
        );
        await _saveToCache(entity);
        return entity;
      }
    } catch (e) {
      // Fallback gracefully to locally cached or default profile
    }
    return await _loadFromCacheOrDefault();
  }

  Future<void> _saveToCache(SettingsEntity s) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('settings_fullName', s.fullName);
      await prefs.setString('settings_email', s.email);
      await prefs.setString('settings_phone', s.phone);
      await prefs.setString('settings_address', s.address);
      await prefs.setString('settings_bio', s.bio);
      await prefs.setString('settings_avatarUrl', s.avatarUrl);
    } catch (_) {}
  }

  Future<SettingsEntity> _loadFromCacheOrDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('settings_fullName') ?? prefs.getString('user_name') ?? 'Athiya Tabassum';
      final email = prefs.getString('settings_email') ?? prefs.getString('user_email') ?? 'athiya160@gmail.com';
      final phone = prefs.getString('settings_phone') ?? prefs.getString('user_phone') ?? '+91 99864 74220';
      final address = prefs.getString('settings_address') ?? prefs.getString('user_address') ?? 'Bangalore, Karnataka, India';
      final bio = prefs.getString('settings_bio') ?? prefs.getString('user_bio') ?? 'Bibliophile, avid reader and community member.';
      final avatar = prefs.getString('settings_avatarUrl') ?? prefs.getString('user_avatar') ?? '';

      return SettingsEntity(
        fullName: name,
        email: email,
        phone: phone,
        address: address,
        bio: bio,
        avatarUrl: avatar,
        notifications: _defaultNotifications,
      );
    } catch (_) {
      return const SettingsEntity(
        fullName: 'Athiya Tabassum',
        email: 'athiya160@gmail.com',
        phone: '+91 99864 74220',
        address: 'Bangalore, Karnataka, India',
        bio: 'Bibliophile, avid reader and community member.',
        avatarUrl: '',
        notifications: _defaultNotifications,
      );
    }
  }

  @override
  Future<void> updateSettings(SettingsEntity settings) async {
    await _saveToCache(settings);
    try {
      await apiClient.putJson(
        '/settings',
        body: {
          'fullName': settings.fullName,
          'email': settings.email,
          'phone': settings.phone,
          'address': settings.address,
          'bio': settings.bio,
          'avatarUrl': settings.avatarUrl,
          'notifications': settings.notifications,
        },
      );
    } catch (e) {
      // Local cache already updated; allow offline edits
    }
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    try {
      await apiClient.postJson(
        '/change-password',
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );
    } catch (e, stackTrace) {
      print('[RemoteSettingsRepository] changePassword error: $e\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<String> uploadAvatar(String imagePath) async {
    try {
      final response = await apiClient.uploadFile('/uploads/image', File(imagePath));
      if (response != null && response is Map<String, dynamic> && response.containsKey('url')) {
        return response['url'].toString();
      }
      throw Exception('Invalid response from server when uploading image');
    } catch (e, stackTrace) {
      print('[RemoteSettingsRepository] uploadAvatar error: $e\n$stackTrace');
      rethrow;
    }
  }
}
