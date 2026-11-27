import '../../../../core/utils/result.dart';
import '../../../home/domain/entities/book.dart';
import '../entities/listing_draft.dart';
import '../repositories/add_book_repository.dart';

class CreateDraft {
  final AddBookRepository repository;

  CreateDraft(this.repository);

  Future<Result<ListingDraft>> fromBook(Book book) {
    return repository.createDraftFromBook(book);
  }

  Future<Result<ListingDraft>> empty(String isbn) {
    return repository.createEmptyDraft(isbn);
  }
}
