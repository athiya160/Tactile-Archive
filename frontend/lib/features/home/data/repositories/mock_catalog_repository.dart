import '../../../../core/data/favorites_data_source.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../../../core/data/mock_catalog_datasource.dart';

class MockCatalogRepository implements CatalogRepository {
  final FavoritesDataSource favoritesDataSource;

  MockCatalogRepository(this.favoritesDataSource);

  @override
  Future<Result<List<Book>>> getFeatured() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final featured = MockCatalogDataSource.books
        .where((b) => b.isStaffPick)
        .map(
          (b) => b.copyWith(isFavorite: favoritesDataSource.isFavorite(b.id)),
        )
        .toList();
    return Result.success(featured);
  }

  @override
  Future<Result<List<String>>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Result.success(MockCatalogDataSource.categories);
  }

  @override
  Future<Result<List<Book>>> getCatalog({
    String? category,
    String? sortBy,
    int page = 1,
    int limit = 10,
    String? searchQuery,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    var filtered = MockCatalogDataSource.books;

    if (category != null && category != 'All Books') {
      filtered = filtered
          .where((b) => b.categories.contains(category))
          .toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (b) =>
                b.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                b.author.toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .toList();
    }

    // Simple sorting
    if (sortBy == 'Recent Arrivals') {
      // Logic for sorting, though mock data doesn't have dates
    }

    // Pagination
    final startIndex = (page - 1) * limit;
    if (startIndex >= filtered.length) {
      return Result.success([]);
    }

    final endIndex = startIndex + limit;
    final paginated = filtered
        .sublist(
          startIndex,
          endIndex > filtered.length ? filtered.length : endIndex,
        )
        .map(
          (b) => b.copyWith(isFavorite: favoritesDataSource.isFavorite(b.id)),
        )
        .toList();

    return Result.success(paginated);
  }
}
