import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import '../error/failures.dart';
import '../config/api_config.dart';

import '../services/api_service.dart';
import '../router/app_router.dart';
import '../data/mock_catalog_datasource.dart';
import '../../features/home/domain/entities/book.dart';

// Mapped dynamically via build configurations or emulator/localhost defaults
const String _envApiUrl = String.fromEnvironment('API_URL');

String getDefaultBaseUrl() {
  if (_envApiUrl.isNotEmpty) {
    if (kReleaseMode) {
      return ApiConfig.resolveProductionApiUrl(explicitUrl: _envApiUrl);
    }
    return _envApiUrl.replaceAll(RegExp(r'/+$'), '');
  }

  if (kIsWeb) {
    try {
      final host = Uri.base.host;
      if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
        if (kReleaseMode) {
          return ApiConfig.resolveProductionApiUrl();
        }
        final scheme = Uri.base.scheme.isNotEmpty ? Uri.base.scheme : 'http';
        return '$scheme://$host:8000';
      }
    } catch (_) {}
    return 'http://localhost:8000';
  } else {
    // In release mode on mobile, enforce validated HTTPS endpoint
    if (kReleaseMode) {
      return ApiConfig.resolveProductionApiUrl();
    }
    // On mobile devices (physical phone or emulator), default to localhost:8000.
    // When using USB debugging, run `adb reverse tcp:8000 tcp:8000` to bind phone localhost to computer.
    // If using Android emulator, 10.0.2.2:8000 is used as alternative fallback.
    return 'http://localhost:8000';
  }
}

class ApiClient {
  final String baseUrl;
  final http.Client httpClient;

  static const Set<String> _nonRetryablePaths = {
    '/payments/verify',
    '/payments/create-order',
    '/orders',
    '/cart/checkout',
    '/checkout',
    '/auth/logout',
    '/auth/refresh',
    '/login',
    '/register',
  };

  ApiClient({http.Client? httpClient, String? baseUrl})
    : httpClient = httpClient ?? http.Client(),
      baseUrl = baseUrl ?? getDefaultBaseUrl();

  Uri buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final uri = Uri.parse('$baseUrl$path');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    return uri.replace(
      queryParameters: queryParameters.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  Map<String, String> get defaultHeaders {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (ApiService.token != null && ApiService.token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${ApiService.token}';
    }
    return headers;
  }



  Future<dynamic> getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool isRetry = false,
  }) async {
    final uri = buildUri(path, queryParameters);
    debugPrint('[ApiClient] GET request to: $uri, headers: $defaultHeaders');
    try {
      final response = await httpClient
          .get(uri, headers: defaultHeaders)
          .timeout(const Duration(seconds: 12));
      debugPrint(
        '[ApiClient] GET response from: $uri status: ${response.statusCode}',
      );
      if (response.statusCode == 401 && !isRetry && ApiService.refreshToken != null && !_nonRetryablePaths.contains(path)) {
        final renewed = await ApiService.refreshAccessToken();
        if (renewed) {
          return getJson(path, queryParameters: queryParameters, isRetry: true);
        }
      }
      return _processResponse(response, path);
    } catch (error) {
      return _handleError(error, path);
    }
  }

  Future<dynamic> postJson(
    String path, {
    Map<String, dynamic>? body,
    bool isRetry = false,
  }) async {
    if (path == '/payments/create-order') {
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'id': 'order_mock_${DateTime.now().millisecondsSinceEpoch}',
        'amount': (body?['amount'] ?? 1000).toInt(),
        'key': 'mock_key_id',
        'is_mock': true,
      };
    }
    if (path == '/payments/verify') {
      await Future.delayed(const Duration(milliseconds: 500));
      return {'status': 'success'};
    }
    
    if (path == '/books') {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final images = (body?['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      final coverUrl = body?['coverUrl'] as String? ?? '';
      
      final newBook = Book(
        id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
        title: body?['title'] ?? 'Unknown Title',
        author: body?['author'] ?? 'Unknown Author',
        coverUrl: coverUrl.isNotEmpty ? coverUrl : (images.isNotEmpty ? images.first : 'https://covers.openlibrary.org/b/id/10521270-L.jpg'),
        categories: [body?['category'] ?? 'Fiction'],
        listingType: body?['listingType'] == 'sell' ? ListingType.forSale : ListingType.forRent,
        rating: 5.0, // newly added books get 5 star rating initially
        price: (body?['price'] as num?)?.toDouble() ?? 0.0,
        description: body?['description'] ?? '',
        isbn: body?['isbn'] ?? '',
        publisher: body?['publisher'] ?? '',
        images: images,
      );
      
      MockCatalogDataSource.books.insert(0, newBook);
      
      return {'status': 'success', 'book_id': newBook.id};
    }

    final uri = buildUri(path);
    debugPrint(
      '[ApiClient] POST request to: $uri, headers: $defaultHeaders, body: $body',
    );
    try {
      final response = await httpClient
          .post(
            uri,
            headers: defaultHeaders,
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      debugPrint(
        '[ApiClient] POST response from: $uri status: ${response.statusCode}',
      );
      if (response.statusCode == 401 && !isRetry && ApiService.refreshToken != null && !_nonRetryablePaths.contains(path)) {
        final renewed = await ApiService.refreshAccessToken();
        if (renewed) {
          return postJson(path, body: body, isRetry: true);
        }
      }
      return _processResponse(response, path);
    } catch (error) {
      return _handleError(error, path);
    }
  }

  Future<dynamic> putJson(
    String path, {
    Map<String, dynamic>? body,
    bool isRetry = false,
  }) async {
    final uri = buildUri(path);
    debugPrint(
      '[ApiClient] PUT request to: $uri, headers: $defaultHeaders, body: $body',
    );
    try {
      final response = await httpClient
          .put(
            uri,
            headers: defaultHeaders,
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      debugPrint(
        '[ApiClient] PUT response from: $uri status: ${response.statusCode}',
      );
      if (response.statusCode == 401 && !isRetry && ApiService.refreshToken != null && !_nonRetryablePaths.contains(path)) {
        final renewed = await ApiService.refreshAccessToken();
        if (renewed) {
          return putJson(path, body: body, isRetry: true);
        }
      }
      return _processResponse(response, path);
    } catch (error) {
      return _handleError(error, path);
    }
  }

  Future<dynamic> deleteJson(
    String path, {
    bool isRetry = false,
  }) async {
    final uri = buildUri(path);
    debugPrint('[ApiClient] DELETE request to: $uri, headers: $defaultHeaders');
    try {
      final response = await httpClient
          .delete(uri, headers: defaultHeaders)
          .timeout(const Duration(seconds: 10));
      debugPrint(
        '[ApiClient] DELETE response from: $uri status: ${response.statusCode}',
      );
      if (response.statusCode == 401 && !isRetry && ApiService.refreshToken != null && !_nonRetryablePaths.contains(path)) {
        final renewed = await ApiService.refreshAccessToken();
        if (renewed) {
          return deleteJson(path, isRetry: true);
        }
      }
      return _processResponse(response, path);
    } catch (error) {
      return _handleError(error, path);
    }
  }

  Future<dynamic> uploadFile(String path, File file) async {
    final uri = buildUri(path);
    debugPrint('[ApiClient] Multipart POST request to: $uri');
    try {
      final request = http.MultipartRequest('POST', uri);
      
      if (ApiService.token != null && ApiService.token!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer ${ApiService.token}';
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      debugPrint('[ApiClient] Multipart POST response status: ${response.statusCode}');
      return _processResponse(response, path);
    } catch (error) {
      return _handleError(error, path);
    }
  }

  Never _handleError(dynamic error, String path) {
    debugPrint('[ApiClient] Request to $path failed with error: $error');
    if (error is Failure) {
      throw error;
    }
    if (error is TimeoutException) {
      throw const NetworkFailure('Server request timed out. Please check your connection.');
    }
    if (error is SocketException) {
      throw const NetworkFailure('Unable to connect to server. Please check your network connection.');
    }
    throw ServerFailure(error.toString());
  }

  dynamic _processResponse(http.Response response, String path) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (error) {
        throw ServerFailure('Invalid JSON from $path');
      }
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      if (ApiService.isLoggedIn) {
        ApiService.logout();
        AppRouter.router.go('/login');
      }
      throw ServerFailure('Session expired or unauthorized.');
    }

    throw ServerFailure('Request failed for $path (${response.statusCode}).');
  }
}
