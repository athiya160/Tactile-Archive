import '../../../../core/utils/result.dart';
import '../entities/book.dart';

abstract class CatalogRepository {
  Future<Result<List<Book>>> getFeatured();
  Future<Result<List<String>>> getCategories();
  Future<Result<List<Book>>> getCatalog({
    String? category,
    String? sortBy,
    int page = 1,
    int limit = 10,
    String? searchQuery,
  });
  // watchFavoriteIds() has been moved to FavoritesRepository (C-5 fix).
}
