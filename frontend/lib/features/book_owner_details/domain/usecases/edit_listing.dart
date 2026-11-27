import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/listing_repository.dart';

class EditListing implements UseCase<void, String> {
  final ListingRepository repository;

  EditListing(this.repository);

  @override
  Future<Result<void>> call(String bookId) async {
    return await repository.editListing(bookId);
  }
}
