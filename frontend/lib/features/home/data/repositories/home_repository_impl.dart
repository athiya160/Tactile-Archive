import '../../../../core/services/api_service.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/catalog_repository.dart';

class HomeRepositoryImpl implements CatalogRepository {
  @override
  Future<Result<List<Book>>> getFeatured() async {
    try {
      final response = await ApiService.getFeaturedBooks();
      final List booksJson = response['data'];
      final books = _mapJsonToBooks(booksJson);
      return Result.success(books);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<String>>> getCategories() async {
    try {
      final categories = await ApiService.getCategories();
      return Result.success(categories);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
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
      final response = await ApiService.getBooks(
        page: page,
        category: category,
        searchQuery: searchQuery,
      );
      final List booksJson = response['data'];
      final books = _mapJsonToBooks(booksJson);
      return Result.success(books);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  List<Book> _mapJsonToBooks(List booksJson) {
    return booksJson.map((json) {
      return Book(
        id: json['id'].toString(),
        title: json['title'] ?? '',
        author: json['author'] ?? '',
        description: json['description'] ?? '',
        coverUrl: json['coverUrl'] ?? json['image_url'] ?? '',
        rating: (json['rating'] ?? 0).toDouble(),
        price: (json['price'] ?? 0).toDouble(),
        categories: [],
        listingType: ListingType.forSale, // Default
        isFavorite: json['isFavorite'] == true,
      );
    }).toList();
  }
}
