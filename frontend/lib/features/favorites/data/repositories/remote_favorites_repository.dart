import 'dart:async';

import '../../../../core/data/favorites_data_source.dart';
import '../../../../core/data/mock_catalog_datasource.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../../../home/data/models/book_model.dart';
import '../../../home/domain/entities/book.dart';
import '../../domain/repositories/favorites_repository.dart';

class RemoteFavoritesRepository implements FavoritesRepository {
  final ApiClient apiClient;
  final FavoritesDataSource favoritesDataSource;

  RemoteFavoritesRepository(this.apiClient, this.favoritesDataSource);

  @override
  Future<Result<List<Book>>> getFavorites() async {
    try {
      final response = await apiClient.getJson('/favorites');
      if (response is List) {
        final books = response
            .map((item) => BookModel.fromJson(item as Map<String, dynamic>))
            .toList();
        favoritesDataSource.setFavorites(
          books.where((book) => book.isFavorite).map((book) => book.id).toSet(),
        );
        return Result.success(books);
      }
    } catch (error) {
      // Fallback to local favoritesDataSource and catalog when server is offline
    }
    final favoriteIds = favoritesDataSource.currentFavorites;
    final fallbackBooks = MockCatalogDataSource.books
        .where((book) => favoriteIds.contains(book.id))
        .map((book) => book.copyWith(isFavorite: true))
        .toList();
    return Result.success(fallbackBooks);
  }

  @override
  Stream<List<Book>> watchFavorites() {
    return favoritesDataSource.favoritesStream.asyncMap((_) async {
      final result = await getFavorites();
      return result.isSuccess ? result.data! : <Book>[];
    });
  }

  @override
  Future<Result<void>> removeFavorite(String bookId) async {
    try {
      await apiClient.deleteJson('/favorites/$bookId');
      favoritesDataSource.removeFavorite(bookId);
      return Result.success(null);
    } on Failure catch (error) {
      return Result.failure(error);
    } catch (error) {
      return Result.failure(ServerFailure(error.toString()));
    }
  }

  @override
  Stream<Set<String>> watchFavoriteIds() {
    return favoritesDataSource.favoritesStream;
  }
}
