import '../entities/draft_listing_review.dart';

abstract class DraftListingRepository {
  Future<DraftListingReview> getDraftReview(String draftId);

  Future<void> publish(String draftId);

  Future<void> saveDraft(String draftId);
}
