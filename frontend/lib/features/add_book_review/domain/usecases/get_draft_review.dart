import '../entities/draft_listing_review.dart';
import '../repositories/draft_listing_repository.dart';

class GetDraftReview {
  final DraftListingRepository repository;

  GetDraftReview(this.repository);

  Future<DraftListingReview> call(String draftId) {
    return repository.getDraftReview(draftId);
  }
}
