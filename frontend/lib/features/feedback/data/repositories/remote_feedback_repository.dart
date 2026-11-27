import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/user_feedback.dart';
import '../../domain/repositories/feedback_repository.dart';

class RemoteFeedbackRepository implements FeedbackRepository {
  final ApiClient apiClient;

  RemoteFeedbackRepository(this.apiClient);

  @override
  Future<Result<void>> submitFeedback(UserFeedback feedback) async {
    try {
      await apiClient.postJson(
        '/feedback',
        body: {
          'rating': feedback.rating,
          'reason': feedback.reason.name,
          'comments': feedback.comments,
        },
      );
      return Result.success(null);
    } on Failure catch (error) {
      return Result.failure(error);
    } catch (error) {
      return Result.failure(ServerFailure(error.toString()));
    }
  }
}
