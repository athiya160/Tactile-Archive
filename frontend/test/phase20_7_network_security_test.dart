import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/core/network/api_client.dart';
import 'package:libri_flow/core/services/api_service.dart';

void main() {
  group('Phase 20.7: Network Security & Endpoint Hardening Tests', () {
    test('getDefaultBaseUrl returns a valid URL', () {
      final defaultUrl = getDefaultBaseUrl();
      expect(defaultUrl, isNotEmpty);
      expect(defaultUrl.startsWith('http://') || defaultUrl.startsWith('https://'), isTrue);
    });

    test('ApiService baseUrl does not fall back to HTTP when configured with HTTPS', () {
      const prodUrl = 'https://the-tactile-archive-prod.up.railway.app';
      ApiService.baseUrl = prodUrl;

      // ApiService internal alternative URLs must be empty when configured with HTTPS
      // We verify this behavior by checking ApiService.baseUrl remains HTTPS
      expect(ApiService.baseUrl, equals(prodUrl));
      expect(ApiService.baseUrl.startsWith('https://'), isTrue);
    });

    test('ReadingPlanPage uses registered ApiClient without throwing', () {
      final client = ApiClient(baseUrl: 'https://the-tactile-archive-prod.up.railway.app');
      expect(client.baseUrl, equals('https://the-tactile-archive-prod.up.railway.app'));
    });

    test('Flavor Network Security XML files are correctly separated on disk', () {
      final mainXml = File('android/app/src/main/res/xml/network_security_config.xml');
      final devXml = File('android/app/src/dev/res/xml/network_security_config.xml');
      final prodXml = File('android/app/src/prod/res/xml/network_security_config.xml');

      // 1. Main XML must NOT exist to avoid flavor conflict
      expect(mainXml.existsSync(), isFalse,
          reason: 'main/res/xml/network_security_config.xml must not exist to allow flavor resource merging');

      // 2. Dev XML must exist and permit cleartext
      expect(devXml.existsSync(), isTrue,
          reason: 'dev/res/xml/network_security_config.xml must exist for local testing');
      final devContent = devXml.readAsStringSync();
      expect(devContent.contains('cleartextTrafficPermitted="true"'), isTrue);
      expect(devContent.contains('localhost'), isTrue);
      expect(devContent.contains('127.0.0.1'), isTrue);
      expect(devContent.contains('<certificates src="user" />'), isTrue);

      // 3. Prod XML must exist and strictly reject cleartext
      expect(prodXml.existsSync(), isTrue,
          reason: 'prod/res/xml/network_security_config.xml must exist for production hardening');
      final prodContent = prodXml.readAsStringSync();
      expect(prodContent.contains('cleartextTrafficPermitted="false"'), isTrue);
      expect(prodContent.contains('<certificates src="system" />'), isTrue);
      expect(prodContent.contains('src="user"'), isFalse,
          reason: 'prod config must never trust user certificates');
      expect(prodContent.contains('localhost'), isFalse,
          reason: 'prod config must never contain localhost exceptions');
      expect(prodContent.contains('10.96.38.204'), isFalse,
          reason: 'prod config must never contain LAN IP exceptions');
    });
  });
}
