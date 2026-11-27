import '../../../../core/utils/result.dart';
import '../entities/listing_draft.dart';
import '../entities/book_copy.dart';

abstract class ListingRepository {
  Future<Result<void>> addCopy(BookCopy copy);
  Future<Result<void>> removeCopy(String id);
  Future<Result<void>> updateCopy(BookCopy copy);
  Future<Result<void>> finalizeListing(ListingDraft draft);
}
