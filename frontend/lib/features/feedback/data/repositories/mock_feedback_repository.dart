import '../../domain/entities/user_feedback.dart';
import '../../domain/repositories/feedback_repository.dart';

class MockFeedbackRepository implements FeedbackRepository {
  @override
  Future<void> submitFeedback(UserFeedback feedback) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Success by default in mock
    if (feedback.comments.toLowerCase() == 'fail') {
      throw Exception('Failed to submit feedback. Please try again.');
    }
  }
}
