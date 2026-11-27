import 'package:equatable/equatable.dart';
import '../../domain/entities/user_feedback.dart';

enum FeedbackStatus { initial, loading, success, failure }

class FeedbackState extends Equatable {
  final UserFeedback feedback;
  final FeedbackStatus status;
  final String? errorMessage;

  const FeedbackState({
    this.feedback = const UserFeedback(
      rating: 0,
      reason: FeedbackReason.suggestion,
      comments: '',
    ),
    this.status = FeedbackStatus.initial,
    this.errorMessage,
  });

  FeedbackState copyWith({
    UserFeedback? feedback,
    FeedbackStatus? status,
    String? errorMessage,
  }) {
    return FeedbackState(
      feedback: feedback ?? this.feedback,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [feedback, status, errorMessage];
}
