import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart';
import '../repositories/book_repository.dart';

class AddToCart {
  final BookRepository repository;

  AddToCart(this.repository);

  Future<Result<void>> call(String id, {bool isPurchase = true}) async {
    // Validate book ID
    if (id.isEmpty) {
      return Result.failure(const ValidationFailure('Book ID cannot be empty'));
    }

    try {
      return await repository.addToCart(id, isPurchase: isPurchase);
    } catch (e) {
      return Result.failure(
        ServerFailure('Failed to add to cart: ${e.toString()}'),
      );
    }
  }
}
