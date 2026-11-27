import 'package:equatable/equatable.dart';

abstract class AddBookReviewEvent extends Equatable {
  const AddBookReviewEvent();

  @override
  List<Object?> get props => [];
}

class AddBookReviewStarted extends AddBookReviewEvent {
  final String draftId;

  const AddBookReviewStarted(this.draftId);

  @override
  List<Object?> get props => [draftId];
}

class AddBookReviewPublishPressed extends AddBookReviewEvent {}

class AddBookReviewSaveDraftPressed extends AddBookReviewEvent {}

class AddBookReviewEditCoverPressed extends AddBookReviewEvent {}
