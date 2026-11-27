import '../../../../core/network/api_client.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/draft_listing_review.dart';
import '../../domain/repositories/draft_listing_repository.dart';

class RemoteDraftListingRepository implements DraftListingRepository {
  final ApiClient apiClient;

  RemoteDraftListingRepository(this.apiClient);
  @override
  Future<DraftListingReview> getDraftReview(String draftId) async {
    try {
      final response = await apiClient.getJson('/drafts/$draftId/review');

      if (response is Map<String, dynamic>) {
        return DraftListingReview(
          id: response['draftId'] ?? draftId,
          title: response['title'] ?? 'Unknown',
          author: response['author'] ?? 'Unknown',
          isbn13: response['isbn13'] ?? 'Unknown',
          editionLabel: response['editionLabel'] ?? '1st Edition',
          coverUrl: response['coverUrl'] ?? 'https://via.placeholder.com/150',
          progressPercent: (response['progressPercent'] ?? 100).toDouble(),
          summaryText: response['summaryText'] ?? '',
          copies: const [],
          standards: const [],
        );
      }
      throw const ServerFailure('Invalid review response format');
    } on Failure catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> publish(String draftId) async {
    try {
      await apiClient.postJson('/drafts/$draftId/publish');
    } on Failure catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> saveDraft(String draftId) async {
    try {
      await apiClient.postJson('/drafts/$draftId/save');
    } on Failure catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
