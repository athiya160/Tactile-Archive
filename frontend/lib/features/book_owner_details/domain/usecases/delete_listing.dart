import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/listing_repository.dart';

class DeleteListing implements UseCase<void, String> {
  final ListingRepository repository;

  DeleteListing(this.repository);

  @override
  Future<Result<void>> call(String bookId) => repository.deleteListing(bookId);
}
