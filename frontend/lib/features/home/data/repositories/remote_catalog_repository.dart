import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../models/book_model.dart';

class RemoteCatalogRepository implements CatalogRepository {
  final ApiClient apiClient;

  RemoteCatalogRepository(this.apiClient);

  @override
  Future<Result<List<Book>>> getFeatured() async {
    try {
      final response = await apiClient.getJson('/books/featured');
      if (response != null && response['data'] is List) {
        final books = (response['data'] as List)
            .map((item) => BookModel.fromJson(item as Map<String, dynamic>))
            .toList();
        return Result.success(books);
      }
      return Result.failure(const ServerFailure('Invalid catalog response'));
    } on Failure catch (error) {
      return Result.failure(error);
    } catch (error) {
      return Result.failure(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Result<List<String>>> getCategories() async {
    try {
      final response = await apiClient.getJson('/books/categories');
      if (response is List) {
        return Result.success(List<String>.from(response));
      }
      return Result.failure(const ServerFailure('Invalid categories response'));
    } on Failure catch (error) {
      return Result.failure(error);
    } catch (error) {
      return Result.failure(ServerFailure(error.toString()));
    }
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
      final String path = (searchQuery != null && searchQuery.trim().isNotEmpty)
          ? '/books/search'
          : '/books';

      final response = await apiClient.getJson(
        path,
        queryParameters: {
          if (searchQuery != null && searchQuery.trim().isNotEmpty)
            'q': searchQuery
          else ...{
            'category': ?category,
            'sortBy': ?sortBy,
            'page': page,
            'limit': limit,
          },
        },
      );
      if (response != null && response['data'] is List) {
        final books = (response['data'] as List)
            .map((item) => BookModel.fromJson(item as Map<String, dynamic>))
            .toList();
        return Result.success(books);
      }
      return Result.failure(
        const ServerFailure('Invalid catalog list response'),
      );
    } on Failure catch (error) {
      return Result.failure(error);
    } catch (error) {
      return Result.failure(ServerFailure(error.toString()));
    }
  }
}
