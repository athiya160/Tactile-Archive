import '../../../../core/utils/result.dart';
import '../entities/listing_draft.dart';
import '../repositories/add_book_repository.dart';

class UpdateCategory {
  final AddBookRepository repository;

  UpdateCategory(this.repository);

  Future<Result<ListingDraft>> call(String category) {
    return repository.updateCategory(category);
  }
}
