import '../repositories/draft_listing_repository.dart';

class SaveDraft {
  final DraftListingRepository repository;

  SaveDraft(this.repository);

  Future<void> call(String draftId) {
    return repository.saveDraft(draftId);
  }
}
