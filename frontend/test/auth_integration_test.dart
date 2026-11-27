import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  group('Authentication Flow Integration Tests', () {
    final String testEmail = 'flutter_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
    const String testPassword = 'Password123!';
    
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      ApiService.baseUrl = 'http://127.0.0.1:8000';
    });

    test('Test 1 - Register: Should successfully register a new user', () async {
      final error = await ApiService.register(
        name: 'Flutter Test User',
        email: testEmail,
        password: testPassword,
        phone: '1234567890'
      );
      
      expect(error, isNull, reason: 'Registration failed with error: $error');
      expect(ApiService.isLoggedIn, isTrue, reason: 'User should be automatically logged in after registration');
      expect(ApiService.token, isNotNull, reason: 'JWT token should be generated and stored in memory');
    });

    test('Test 2 - Login: Should successfully log in and receive JWT', () async {
      // Clear memory state to simulate fresh login
      ApiService.token = null;
      ApiService.role = UserRole.none;
      ApiService.authState.value = false;
      
      final error = await ApiService.login(testEmail, testPassword);
      
      expect(error, isNull, reason: 'Login failed with error: $error');
      expect(ApiService.isLoggedIn, isTrue, reason: 'User should be logged in');
      expect(ApiService.token, isNotNull, reason: 'JWT token should be received');
    });

    test('Test 3 - Restart App: Should persist token', () async {
      // Simulate app restart by clearing memory state but keeping SharedPreferences
      ApiService.token = null;
      ApiService.role = UserRole.none;
      ApiService.authState.value = false;
      
      // Call loadToken which runs on app startup
      await ApiService.loadToken();
      
      expect(ApiService.isLoggedIn, isTrue, reason: 'User should still be logged in after restart');
      expect(ApiService.token, isNotNull, reason: 'JWT token should be retrieved from SharedPreferences');
    });

    test('Test 4 - Logout: Should clear token and logout', () async {
      await ApiService.logout();
      
      expect(ApiService.isLoggedIn, isFalse, reason: 'User should no longer be logged in');
      expect(ApiService.token, isNull, reason: 'JWT token should be cleared from memory');
      
      // Verify SharedPreferences is also cleared
      await ApiService.loadToken();
      expect(ApiService.isLoggedIn, isFalse, reason: 'Token should be permanently deleted from storage');
    });
  });
}
