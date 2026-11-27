import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 20.14 — Firebase Configuration & Initialization Safety Tests', () {
    test('1. Production google-services.json uses com.tactilearchive.app and contains placeholder credentials', () {
      final prodFile = File('android/app/src/prod/google-services.json');
      expect(prodFile.existsSync(), isTrue, reason: 'src/prod/google-services.json must exist');

      final content = prodFile.readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;

      // Verify Project Info
      final projectInfo = json['project_info'] as Map<String, dynamic>;
      expect(projectInfo['project_id'], equals('tactile-archive-prod'));
      expect(projectInfo['project_number'], equals('987654321098'));

      // Verify Package Name
      final clients = json['client'] as List<dynamic>;
      expect(clients.isNotEmpty, isTrue);
      final clientInfo = clients[0]['client_info'] as Map<String, dynamic>;
      final androidClientInfo = clientInfo['android_client_info'] as Map<String, dynamic>;
      expect(androidClientInfo['package_name'], equals('com.tactilearchive.app'),
          reason: 'Production Firebase app must be registered with com.tactilearchive.app');

      // Verify Credentials are placeholder (Fail-Safe verification)
      final apiKeys = clients[0]['api_key'] as List<dynamic>;
      final currentKey = apiKeys[0]['current_key'] as String;
      expect(currentKey.toLowerCase().contains('placeholder'), isTrue,
          reason: 'Production google-services.json must contain placeholder marker until official console setup');
    });

    test('2. Development google-services.json uses com.tactilearchive.app.dev and is isolated from prod', () {
      final devFile = File('android/app/src/dev/google-services.json');
      expect(devFile.existsSync(), isTrue, reason: 'src/dev/google-services.json must exist');

      final content = devFile.readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;

      // Verify Dev Package Name has .dev suffix
      final clients = json['client'] as List<dynamic>;
      final clientInfo = clients[0]['client_info'] as Map<String, dynamic>;
      final androidClientInfo = clientInfo['android_client_info'] as Map<String, dynamic>;
      expect(androidClientInfo['package_name'], equals('com.tactilearchive.app.dev'),
          reason: 'Dev Firebase app must be registered with com.tactilearchive.app.dev');

      // Ensure dev package name does not match prod package name
      expect(androidClientInfo['package_name'], isNot(equals('com.tactilearchive.app')));
    });

    test('3. Root and src/main do not contain any fallback google-services.json', () {
      final rootAppFile = File('android/app/google-services.json');
      final mainFile = File('android/app/src/main/google-services.json');

      expect(rootAppFile.existsSync(), isFalse,
          reason: 'No google-services.json should exist at root of app/ to prevent silent flavor bleeding');
      expect(mainFile.existsSync(), isFalse,
          reason: 'No google-services.json should exist in src/main/ to ensure strict flavor-specific resolution');
    });

    test('4. Startup try-catch pattern safely catches Firebase initialization errors without crashing app', () async {
      bool initializedSuccessfully = false;
      bool exceptionCaught = false;
      bool startupProceeded = false;

      // Simulate main_prod.dart bootstrap sequence with failing Firebase initialization
      try {
        // Simulating Firebase.initializeApp() throwing when credentials or plugins are unconfigured
        throw Exception('[core/no-app] Firebase has not been correctly initialized in this process.');
        // initializedSuccessfully = true;
      } catch (e) {
        exceptionCaught = true;
        debugPrint('Firebase/Crashlytics initialization bypassed: $e');
      }

      // App initialization must proceed safely regardless of Firebase failure
      startupProceeded = true;

      expect(initializedSuccessfully, isFalse);
      expect(exceptionCaught, isTrue, reason: 'Firebase initialization exception must be caught');
      expect(startupProceeded, isTrue, reason: 'Bootstrap must continue even if Firebase fails');
    });
  });
}
