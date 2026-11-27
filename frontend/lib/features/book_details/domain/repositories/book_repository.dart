import '../../../home/domain/entities/book.dart';

import '../../../../core/utils/result.dart';

abstract class BookRepository {
  Future<Result<Book>> getBookDetails(String id);

  Future<Result<bool>> toggleFavorite(String id);

  Future<Result<void>> addToCart(String id, {bool isPurchase = true});

  Future<Result<void>> borrowBook(String id, int durationDays, {String? message});
}
