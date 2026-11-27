import 'package:equatable/equatable.dart';
import '../../domain/entities/draft_listing_review.dart';

abstract class AddBookReviewState extends Equatable {
  const AddBookReviewState();

  @override
  List<Object?> get props => [];
}

class AddBookReviewInitial extends AddBookReviewState {}

class AddBookReviewLoading extends AddBookReviewState {}

class AddBookReviewLoaded extends AddBookReviewState {
  final DraftListingReview review;

  const AddBookReviewLoaded(this.review);

  @override
  List<Object?> get props => [review];
}

class AddBookReviewActionInProgress extends AddBookReviewState {
  final DraftListingReview review;
  final String action; // 'publishing' or 'saving'

  const AddBookReviewActionInProgress(this.review, this.action);

  @override
  List<Object?> get props => [review, action];
}

class AddBookReviewSuccess extends AddBookReviewState {
  final String message;

  const AddBookReviewSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AddBookReviewError extends AddBookReviewState {
  final String message;

  const AddBookReviewError(this.message);

  @override
  List<Object?> get props => [message];
}
