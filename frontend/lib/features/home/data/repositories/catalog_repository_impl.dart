import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/book.dart';
import '../models/book_model.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../../../core/services/api_service.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  @override
  Future<Result<List<Book>>> getFeatured() async {
    return Result.success([]);
  }

  @override
  Future<Result<List<String>>> getCategories() async {
    return Result.success([]);
  }

  @override
  Future<Result<List<Book>>> getCatalog({
    String? category,
    String? sortBy,
    int page = 1,
    int limit = 10,
    String? searchQuery,
  }) async {
    try {
      final token = ApiService.token;

      final response = await http
          .get(
            Uri.parse("${ApiService.baseUrl}/books"),
            headers: {"Authorization": "Bearer $token"},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        final books = data.map((e) => BookModel.fromJson(e)).toList();

        return Result.success(books);
      } else {
        return Result.failure(ServerFailure("Failed to fetch books"));
      }
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}
