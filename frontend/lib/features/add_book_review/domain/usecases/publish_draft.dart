import '../repositories/draft_listing_repository.dart';

class PublishDraft {
  final DraftListingRepository repository;

  PublishDraft(this.repository);

  Future<void> call(String draftId) {
    return repository.publish(draftId);
  }
}
