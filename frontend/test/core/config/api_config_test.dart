import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/core/config/api_config.dart';

void main() {
  group('ApiConfig - Development URL Resolution', () {
    test('returns explicit development URL when provided', () {
      final url = ApiConfig.resolveDevelopmentApiUrl(
        explicitUrl: 'http://192.168.1.50:8000',
      );
      expect(url, equals('http://192.168.1.50:8000'));
    });

    test('strips trailing slashes from explicit development URL', () {
      final url = ApiConfig.resolveDevelopmentApiUrl(
        explicitUrl: 'http://localhost:8000///',
      );
      expect(url, equals('http://localhost:8000'));
    });

    test('falls back to fallbackDefault when explicitUrl is null or empty', () {
      final urlWithNull = ApiConfig.resolveDevelopmentApiUrl(
        explicitUrl: null,
        fallbackDefault: 'http://10.0.2.2:8000',
      );
      expect(urlWithNull, equals('http://10.0.2.2:8000'));

      final urlWithEmpty = ApiConfig.resolveDevelopmentApiUrl(
        explicitUrl: '   ',
        fallbackDefault: 'http://10.0.2.2:8000',
      );
      expect(urlWithEmpty, equals('http://10.0.2.2:8000'));
    });

    test('falls back to localhost:8000 when both explicitUrl and fallbackDefault are omitted', () {
      final url = ApiConfig.resolveDevelopmentApiUrl(
        explicitUrl: null,
        fallbackDefault: null,
      );
      expect(url, equals('http://localhost:8000'));
    });
  });

  group('ApiConfig - Production URL Resolution (Valid)', () {
    test('resolves valid HTTPS production URL successfully', () {
      final url = ApiConfig.resolveProductionApiUrl(
        explicitUrl: 'https://api.tactilearchive.org',
      );
      expect(url, equals('https://api.tactilearchive.org'));
    });

    test('strips trailing slashes on valid HTTPS production URL', () {
      final url = ApiConfig.resolveProductionApiUrl(
        explicitUrl: 'https://api.tactilearchive.org///',
      );
      expect(url, equals('https://api.tactilearchive.org'));
    });

    test('accepts valid HTTPS production URL with custom port or path', () {
      final urlWithPort = ApiConfig.resolveProductionApiUrl(
        explicitUrl: 'https://api.tactilearchive.org:8443',
      );
      expect(urlWithPort, equals('https://api.tactilearchive.org:8443'));

      final urlWithPath = ApiConfig.resolveProductionApiUrl(
        explicitUrl: 'https://api.tactilearchive.org/v1',
      );
      expect(urlWithPath, equals('https://api.tactilearchive.org/v1'));
    });
  });

  group('ApiConfig - Missing URL Validation', () {
    test('throws ProductionConfigException when explicitUrl is empty string', () {
      expect(
        () => ApiConfig.resolveProductionApiUrl(explicitUrl: ''),
        throwsA(
          isA<ProductionConfigException>().having(
            (e) => e.message,
            'message',
            contains('Production API_URL is unset'),
          ),
        ),
      );
    });

    test('throws ProductionConfigException when explicitUrl is whitespace only', () {
      expect(
        () => ApiConfig.resolveProductionApiUrl(explicitUrl: '    '),
        throwsA(
          isA<ProductionConfigException>().having(
            (e) => e.message,
            'message',
            contains('Production API_URL is unset'),
          ),
        ),
      );
    });

    test('error message guides user towards build configuration without exposing secrets', () {
      try {
        ApiConfig.resolveProductionApiUrl(explicitUrl: '');
        fail('Expected ProductionConfigException');
      } on ProductionConfigException catch (e) {
        expect(e.message, contains('--dart-define=API_URL='));
        expect(e.message, contains('.env.prod'));
        expect(e.message.contains('password'), isFalse);
        expect(e.message.contains('secret'), isFalse);
        expect(e.message.contains('token'), isFalse);
      }
    });
  });

  group('ApiConfig - Insecure & Invalid URL Validation', () {
    test('throws ProductionConfigException when URL uses HTTP cleartext', () {
      expect(
        () => ApiConfig.resolveProductionApiUrl(
          explicitUrl: 'http://api.tactilearchive.org',
        ),
        throwsA(
          isA<ProductionConfigException>().having(
            (e) => e.message,
            'message',
            contains('must use the HTTPS scheme'),
          ),
        ),
      );
    });

    test('throws ProductionConfigException when URL has invalid/unsupported scheme', () {
      expect(
        () => ApiConfig.resolveProductionApiUrl(
          explicitUrl: 'ftp://api.tactilearchive.org',
        ),
        throwsA(
          isA<ProductionConfigException>().having(
            (e) => e.message,
            'message',
            contains('must use the HTTPS scheme'),
          ),
        ),
      );
    });

    test('throws ProductionConfigException when URL is malformed or missing authority', () {
      expect(
        () => ApiConfig.resolveProductionApiUrl(
          explicitUrl: 'not_a_valid_url',
        ),
        throwsA(
          isA<ProductionConfigException>().having(
            (e) => e.message,
            'message',
            contains('malformed'),
          ),
        ),
      );

      expect(
        () => ApiConfig.resolveProductionApiUrl(
          explicitUrl: 'https://',
        ),
        throwsA(
          isA<ProductionConfigException>().having(
            (e) => e.message,
            'message',
            contains('malformed'),
          ),
        ),
      );
    });

    test('throws ProductionConfigException when URL targets localhost or loopback', () {
      expect(
        () => ApiConfig.resolveProductionApiUrl(
          explicitUrl: 'https://localhost:8000',
        ),
        throwsA(
          isA<ProductionConfigException>().having(
            (e) => e.message,
            'message',
            contains('cannot target local loopback address'),
          ),
        ),
      );

      expect(
        () => ApiConfig.resolveProductionApiUrl(
          explicitUrl: 'https://127.0.0.1:8000',
        ),
        throwsA(
          isA<ProductionConfigException>().having(
            (e) => e.message,
            'message',
            contains('cannot target local loopback address'),
          ),
        ),
      );

      expect(
        () => ApiConfig.resolveProductionApiUrl(
          explicitUrl: 'https://10.0.2.2:8000',
        ),
        throwsA(
          isA<ProductionConfigException>().having(
            (e) => e.message,
            'message',
            contains('cannot target local loopback address'),
          ),
        ),
      );
    });

    test('throws ProductionConfigException when URL targets private LAN ranges', () {
      expect(
        () => ApiConfig.resolveProductionApiUrl(
          explicitUrl: 'https://192.168.1.150:8000',
        ),
        throwsA(
          isA<ProductionConfigException>().having(
            (e) => e.message,
            'message',
            contains('private local area network'),
          ),
        ),
      );

      expect(
        () => ApiConfig.resolveProductionApiUrl(
          explicitUrl: 'https://10.96.38.204:8000',
        ),
        throwsA(
          isA<ProductionConfigException>().having(
            (e) => e.message,
            'message',
            contains('private local area network'),
          ),
        ),
      );

      expect(
        () => ApiConfig.resolveProductionApiUrl(
          explicitUrl: 'https://172.20.10.4:8000',
        ),
        throwsA(
          isA<ProductionConfigException>().having(
            (e) => e.message,
            'message',
            contains('private local area network'),
          ),
        ),
      );
    });
  });
}
