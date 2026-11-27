import '../../../../core/utils/result.dart';
import '../../../home/domain/entities/book.dart';
import '../repositories/book_repository.dart';

class GetBookDetails {
  final BookRepository repository;

  GetBookDetails(this.repository);

  Future<Result<Book>> call(String id) async {
    return await repository.getBookDetails(id);
  }
}
