import '../../../../core/data/favorites_data_source.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/data/mock_catalog_datasource.dart';
import '../../../home/domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../../../cart/data/datasources/cart_data_source.dart';
import '../../../cart/domain/entities/cart_item.dart';

class MockBookRepository implements BookRepository {
  final FavoritesDataSource favoritesDataSource;
  final CartDataSource cartDataSource;

  MockBookRepository(this.favoritesDataSource, this.cartDataSource);

  @override
  Future<Result<Book>> getBookDetails(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final book = MockCatalogDataSource.books.firstWhere((b) => b.id == id);
      return Result.success(
        book.copyWith(isFavorite: favoritesDataSource.isFavorite(id)),
      );
    } catch (e) {
      return Result.failure(const ServerFailure('Book not found'));
    }
  }

  @override
  Future<Result<bool>> toggleFavorite(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final isFavorite = favoritesDataSource.toggleFavorite(id);
    return Result.success(isFavorite);
  }

  @override
  Future<Result<void>> addToCart(String id, {bool isPurchase = true}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final book = MockCatalogDataSource.books.firstWhere((b) => b.id == id);
      final currentCart = cartDataSource.currentCart;

      // Check if already in cart
      if (currentCart.items.any((item) => item.bookId == id)) {
        return Result.success(null);
      }

      final newItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        bookId: book.id,
        title: book.title,
        author: book.author,
        coverUrl: book.coverUrl,
        price: isPurchase ? book.price : (book.price * 0.2),
        isPurchase: isPurchase,
        rentalDays: isPurchase ? null : 30,
      );

      final updatedItems = List<CartItem>.from(currentCart.items)..add(newItem);
      cartDataSource.updateCart(currentCart.copyWith(items: updatedItems));

      return Result.success(null);
    } catch (e) {
      return Result.failure(const ServerFailure('Book not found'));
    }
  }

  @override
  Future<Result<void>> borrowBook(String id, int durationDays, {String? message}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // No-op for mock

    return Result.success(null);
  }
}
