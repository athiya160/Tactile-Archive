import 'package:equatable/equatable.dart';
import '../../domain/entities/user_feedback.dart';

abstract class FeedbackEvent extends Equatable {
  const FeedbackEvent();

  @override
  List<Object?> get props => [];
}

class FeedbackStarted extends FeedbackEvent {}

class FeedbackRatingChanged extends FeedbackEvent {
  final int rating;
  const FeedbackRatingChanged(this.rating);

  @override
  List<Object?> get props => [rating];
}

class FeedbackReasonChanged extends FeedbackEvent {
  final FeedbackReason reason;
  const FeedbackReasonChanged(this.reason);

  @override
  List<Object?> get props => [reason];
}

class FeedbackCommentsChanged extends FeedbackEvent {
  final String comments;
  const FeedbackCommentsChanged(this.comments);

  @override
  List<Object?> get props => [comments];
}

class FeedbackSubmitted extends FeedbackEvent {}
