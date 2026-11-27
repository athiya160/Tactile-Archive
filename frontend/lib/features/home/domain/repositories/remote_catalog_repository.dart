import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/api_service.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/catalog_repository.dart';

class RemoteCatalogRepository implements CatalogRepository {
  final String baseUrl = ApiService.baseUrl;

  Book _mapJsonToBook(Map<String, dynamic> json) {
    return Book(
      id: json['id'].toString(),
      title: json['title'] ?? 'Unknown Title',
      author: json['author'] ?? 'Unknown Author',
      coverUrl: json['coverUrl'] ?? json['cover_url'] ?? '',
      categories: json['category'] != null ? [json['category']] : [],
      category: json['category'] ?? 'Uncategorized',
      price: (json['price'] ?? 0.0).toDouble(),
      stock: json['stock'] as int? ?? 1,
      listingType: ListingType.forSale,
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      description: json['description'] ?? '',
      publisher: json['publisher'] ?? '',
      language: json['language'] ?? '',
      isbn: json['isbn'] ?? '',
      isFavorite: json['isFavorite'] ?? false,
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  @override
  Future<Result<List<Book>>> getCatalog({
    String? category,
    String? sortBy,
    int page = 1,
    int limit = 10,
    String? searchQuery,
  }) async {
    final token = ApiService.token;
    
    // Build query parameters
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (category != null && category.isNotEmpty && category != 'All Books') {
      queryParams['category'] = category;
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      queryParams['q'] = searchQuery;
    }

    final uri = Uri.parse("$baseUrl/books").replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: token != null ? {"Authorization": "Bearer $token"} : {},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> booksJson = data['data'] ?? [];
        final books = booksJson.map((e) => _mapJsonToBook(e as Map<String, dynamic>)).toList();
        return Result.success(books);
      } else {
        return Result.failure(ServerFailure("Failed to load catalog: ${response.statusCode}"));
      }
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<String>>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/books/categories"),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return Result.success(data.map((e) => e.toString()).toList());
      } else {
        return Result.failure(ServerFailure("Failed to load categories: ${response.statusCode}"));
      }
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<Book>>> getFeatured() async {
    final token = ApiService.token;
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/books/featured"),
        headers: token != null ? {"Authorization": "Bearer $token"} : {},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> booksJson = data['data'] ?? [];
        final books = booksJson.map((e) => _mapJsonToBook(e as Map<String, dynamic>)).toList();
        return Result.success(books);
      } else {
        return Result.failure(ServerFailure("Failed to load featured books: ${response.statusCode}"));
      }
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}
