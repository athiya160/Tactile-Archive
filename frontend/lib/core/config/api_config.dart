/// Unified API configuration manager for development, test, and production builds.
///
/// Ensures production builds enforce HTTPS and prevent silent fallbacks to
/// loopback or obsolete placeholder domains, while allowing development builds
/// to operate seamlessly with local and emulator environments.
library;

/// Exception thrown when production API configuration is missing or invalid.
class ProductionConfigException implements Exception {
  final String message;

  const ProductionConfigException(this.message);

  @override
  String toString() => 'ProductionConfigException: $message';
}

/// Unified API configuration resolver and validator.
class ApiConfig {
  /// Default local development fallback port
  static const int defaultPort = 8000;

  /// Private IP / loopback indicators that must never be used as a production API URL.
  static const List<String> _forbiddenProductionHosts = [
    'localhost',
    '127.0.0.1',
    '10.0.2.2',
    '0.0.0.0',
  ];

  /// Resolves and strictly validates the production API URL.
  ///
  /// In production releases, the API URL MUST be explicitly provided via:
  /// - `--dart-define=API_URL=https://<your-backend-domain>`
  /// - or `--dart-define-from-file=.env.prod`
  ///
  /// Enforces:
  /// 1. Non-empty value (throws [ProductionConfigException] if missing or unset).
  /// 2. Valid HTTPS URI scheme (`https://...`). Cleartext HTTP is strictly prohibited.
  /// 3. Valid authority and host (cannot be empty, localhost, or private loopback).
  /// 4. Strips any trailing slashes for consistent endpoint concatenation.
  ///
  /// Never logs or displays sensitive tokens, credentials, or keys.
  static String resolveProductionApiUrl({String? explicitUrl}) {
    const compileTimeUrl = String.fromEnvironment('API_URL');
    final rawUrl = (explicitUrl ?? compileTimeUrl).trim();

    if (rawUrl.isEmpty) {
      throw const ProductionConfigException(
        'Production API_URL is unset. You must supply a valid HTTPS production backend URL '
        'using --dart-define=API_URL=<url> or --dart-define-from-file=.env.prod during release build.',
      );
    }

    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority || uri.host.isEmpty) {
      throw const ProductionConfigException(
        'Production API_URL is malformed. A fully qualified URI with host is required (e.g., https://api.tactilearchive.org).',
      );
    }

    if (uri.scheme.toLowerCase() != 'https') {
      throw const ProductionConfigException(
        'Production API_URL must use the HTTPS scheme ("https://..."). Cleartext HTTP is prohibited in production builds.',
      );
    }

    final lowerHost = uri.host.toLowerCase();
    for (final forbidden in _forbiddenProductionHosts) {
      if (lowerHost == forbidden) {
        throw ProductionConfigException(
          'Production API_URL cannot target local loopback address "$forbidden". A live production domain is required.',
        );
      }
    }

    if (lowerHost.startsWith('192.168.') ||
        lowerHost.startsWith('10.') ||
        (lowerHost.startsWith('172.') && _isPrivateClassB(lowerHost))) {
      throw const ProductionConfigException(
        'Production API_URL cannot target private local area network (LAN) IP addresses.',
      );
    }

    // Strip trailing slashes
    return rawUrl.replaceAll(RegExp(r'/+$'), '');
  }

  static bool _isPrivateClassB(String host) {
    final parts = host.split('.');
    if (parts.length >= 2) {
      final secondOctet = int.tryParse(parts[1]);
      if (secondOctet != null && secondOctet >= 16 && secondOctet <= 31) {
        return true;
      }
    }
    return false;
  }

  /// Resolves the development API URL.
  ///
  /// Order of precedence:
  /// 1. Explicit [explicitUrl] if passed.
  /// 2. Compile-time `--dart-define=API_URL` if non-empty.
  /// 3. Environment/platform fallback provided by [fallbackDefault] or default emulator/LAN URL.
  static String resolveDevelopmentApiUrl({
    String? explicitUrl,
    String? fallbackDefault,
  }) {
    const compileTimeUrl = String.fromEnvironment('API_URL');
    final candidate = (explicitUrl ?? (compileTimeUrl.isNotEmpty ? compileTimeUrl : null))?.trim();

    if (candidate != null && candidate.isNotEmpty) {
      return candidate.replaceAll(RegExp(r'/+$'), '');
    }

    if (fallbackDefault != null && fallbackDefault.isNotEmpty) {
      return fallbackDefault.replaceAll(RegExp(r'/+$'), '');
    }

    return 'http://localhost:$defaultPort';
  }
}
