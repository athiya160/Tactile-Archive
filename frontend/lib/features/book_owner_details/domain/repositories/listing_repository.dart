import '../../../../core/utils/result.dart';

import '../entities/listing_details.dart';

abstract class ListingRepository {
  Future<Result<ListingDetails>> getListingDetails(String bookId);

  Future<Result<void>> editListing(String bookId);

  Future<Result<void>> deleteListing(String bookId);
}
