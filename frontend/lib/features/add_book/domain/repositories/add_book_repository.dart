import '../../../../core/utils/result.dart';
import '../../../home/domain/entities/book.dart';
import '../entities/listing_draft.dart';

abstract class AddBookRepository {
  Future<Result<Book?>> lookupIsbn(String isbn);
  Future<Result<ListingDraft>> createDraftFromBook(Book book);
  Future<Result<ListingDraft>> createEmptyDraft(String isbn);
  Future<Result<ListingDraft>> updateCategory(String category);
  Future<Result<ListingDraft>> getCurrentDraft();
}
