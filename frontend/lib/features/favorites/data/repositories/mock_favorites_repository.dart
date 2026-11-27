import '../../../../core/data/favorites_data_source.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/data/mock_catalog_datasource.dart';
import '../../../home/domain/entities/book.dart';
import '../../domain/repositories/favorites_repository.dart';

class MockFavoritesRepository implements FavoritesRepository {
  final FavoritesDataSource favoritesDataSource;

  MockFavoritesRepository(this.favoritesDataSource);

  @override
  Future<Result<List<Book>>> getFavorites() async {
    await Future.delayed(const Duration(milliseconds: 600));
    final favorites = MockCatalogDataSource.books
        .where((book) => favoritesDataSource.isFavorite(book.id))
        .map((book) => book.copyWith(isFavorite: true))
        .toList();
    return Result.success(favorites);
  }

  @override
  Stream<List<Book>> watchFavorites() {
    return favoritesDataSource.favoritesStream.map((ids) {
      return MockCatalogDataSource.books
          .where((book) => ids.contains(book.id))
          .map((book) => book.copyWith(isFavorite: true))
          .toList();
    });
  }

  @override
  Future<Result<void>> removeFavorite(String bookId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    favoritesDataSource.removeFavorite(bookId);
    return Result.success(null);
  }

  @override
  Stream<Set<String>> watchFavoriteIds() {
    // Delegates to the same FavoritesDataSource stream used by watchFavorites(),
    // ensuring both streams are backed by the same source of truth.
    return favoritesDataSource.favoritesStream;
  }
}
