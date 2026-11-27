import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../../../home/data/models/book_model.dart';
import '../../../home/domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../../../../core/data/favorites_data_source.dart';

import '../../../../core/data/mock_catalog_datasource.dart';

class RemoteBookRepository implements BookRepository {
  final ApiClient apiClient;
  final FavoritesDataSource favoritesDataSource;

  RemoteBookRepository(this.apiClient, this.favoritesDataSource);

  @override
  Future<Result<Book>> getBookDetails(String id) async {
    try {
      final response = await apiClient.getJson('/books/$id');
      if (response is Map<String, dynamic>) {
        final book = BookModel.fromJson(response);
        return Result.success(book);
      }
      return Result.failure(const ServerFailure('Book listing not found or unavailable.'));
    } catch (e) {
      final matching = MockCatalogDataSource.books.where((b) => b.id == id);
      if (matching.isNotEmpty) {
        return Result.success(matching.first);
      }
      return Result.failure(ServerFailure('Unable to load listing: $e'));
    }
  }

  @override
  Future<Result<bool>> toggleFavorite(String id) async {
    try {
      final response = await apiClient.postJson('/books/$id/favorite');
      if (response is Map<String, dynamic>) {
        final isFavorite = response['isFavorite'] == true;
        final currentIds = favoritesDataSource.currentFavorites;
        if (isFavorite) {
          favoritesDataSource.setFavorites({...currentIds, id});
        } else {
          favoritesDataSource.removeFavorite(id);
        }
        return Result.success(isFavorite);
      }
    } catch (_) {
      // Fallback offline toggle
      final currentIds = favoritesDataSource.currentFavorites;
      final isFav = currentIds.contains(id);
      if (isFav) {
        favoritesDataSource.removeFavorite(id);
        return Result.success(false);
      } else {
        favoritesDataSource.setFavorites({...currentIds, id});
        return Result.success(true);
      }
    }
    return Result.success(false);
  }

  @override
  Future<Result<void>> addToCart(String id, {bool isPurchase = true}) async {
    try {
      await apiClient.postJson(
        '/cart/items',
        body: {'bookId': int.tryParse(id) ?? id, 'isPurchase': isPurchase},
      );
      return Result.success(null);
    } on Failure catch (error) {
      return Result.failure(error);
    } catch (error) {
      return Result.failure(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Result<void>> borrowBook(String id, int durationDays, {String? message}) async {
    try {
      await apiClient.postJson(
        '/orders/borrow',
        body: {
          'book_id': int.tryParse(id) ?? id,
          'duration_days': durationDays,
          'message': ?message,
        },
      );
      return Result.success(null);
    } on Failure catch (error) {
      return Result.failure(error);
    } catch (error) {
      return Result.failure(ServerFailure(error.toString()));
    }
  }
}
