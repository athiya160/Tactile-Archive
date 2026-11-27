import '../entities/user_feedback.dart';

abstract class FeedbackRepository {
  Future<void> submitFeedback(UserFeedback feedback);
}
