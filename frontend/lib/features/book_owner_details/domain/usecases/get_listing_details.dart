import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/listing_details.dart';
import '../repositories/listing_repository.dart';

class GetListingDetails implements UseCase<ListingDetails, String> {
  final ListingRepository repository;

  GetListingDetails(this.repository);

  @override
  Future<Result<ListingDetails>> call(String bookId) async {
    return await repository.getListingDetails(bookId);
  }
}
