import 'package:equatable/equatable.dart';

enum FeedbackReason {
  suggestion('Suggestion'),
  bugReport('Bug Report'),
  praise('Praise'),
  other('Other');

  final String label;
  const FeedbackReason(this.label);
}

class UserFeedback extends Equatable {
  final int rating;
  final FeedbackReason reason;
  final String comments;

  const UserFeedback({
    required this.rating,
    required this.reason,
    required this.comments,
  });

  UserFeedback copyWith({
    int? rating,
    FeedbackReason? reason,
    String? comments,
  }) {
    return UserFeedback(
      rating: rating ?? this.rating,
      reason: reason ?? this.reason,
      comments: comments ?? this.comments,
    );
  }

  @override
  List<Object?> get props => [rating, reason, comments];
}
