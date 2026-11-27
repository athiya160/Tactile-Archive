import '../../../../core/utils/result.dart';
import '../../../home/domain/entities/book.dart';
import '../repositories/add_book_repository.dart';

class LookupIsbn {
  final AddBookRepository repository;

  LookupIsbn(this.repository);

  Future<Result<Book?>> call(String isbn) {
    return repository.lookupIsbn(isbn);
  }
}
