import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_feedback.dart';
import '../repositories/feedback_repository.dart';

class SubmitFeedback implements UseCase<void, UserFeedback> {
  final FeedbackRepository repository;

  SubmitFeedback(this.repository);

  @override
  Future<Result<void>> call(UserFeedback feedback) async {
    // Validate feedback input
    if (feedback.rating < 1 || feedback.rating > 5) {
      return Result.failure(
        const ValidationFailure('Rating must be between 1 and 5'),
      );
    }
    if (feedback.comments.isEmpty) {
      return Result.failure(
        const ValidationFailure('Comments cannot be empty'),
      );
    }

    try {
      await repository.submitFeedback(feedback);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        ServerFailure('Failed to submit feedback: ${e.toString()}'),
      );
    }
  }
}
