import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_draft_review.dart';
import '../../domain/usecases/publish_draft.dart';
import '../../domain/usecases/save_draft.dart';
import 'add_book_review_event.dart';
import 'add_book_review_state.dart';

class AddBookReviewBloc extends Bloc<AddBookReviewEvent, AddBookReviewState> {
  final GetDraftReview getDraftReview;
  final PublishDraft publishDraft;
  final SaveDraft saveDraft;

  AddBookReviewBloc({
    required this.getDraftReview,
    required this.publishDraft,
    required this.saveDraft,
  }) : super(AddBookReviewInitial()) {
    on<AddBookReviewStarted>(_onStarted);
    on<AddBookReviewPublishPressed>(_onPublishPressed);
    on<AddBookReviewSaveDraftPressed>(_onSaveDraftPressed);
  }

  Future<void> _onStarted(
    AddBookReviewStarted event,
    Emitter<AddBookReviewState> emit,
  ) async {
    emit(AddBookReviewLoading());
    try {
      final review = await getDraftReview(event.draftId);
      emit(AddBookReviewLoaded(review));
    } catch (e) {
      emit(AddBookReviewError(e.toString()));
    }
  }

  Future<void> _onPublishPressed(
    AddBookReviewPublishPressed event,
    Emitter<AddBookReviewState> emit,
  ) async {
    final currentState = state;
    if (currentState is AddBookReviewLoaded) {
      emit(AddBookReviewActionInProgress(currentState.review, 'publishing'));
      try {
        await publishDraft(currentState.review.id);
        emit(const AddBookReviewSuccess("Published successfully to Archive"));
      } catch (e) {
        emit(AddBookReviewError(e.toString()));
        emit(AddBookReviewLoaded(currentState.review));
      }
    }
  }

  Future<void> _onSaveDraftPressed(
    AddBookReviewSaveDraftPressed event,
    Emitter<AddBookReviewState> emit,
  ) async {
    final currentState = state;
    if (currentState is AddBookReviewLoaded) {
      emit(AddBookReviewActionInProgress(currentState.review, 'saving'));
      try {
        await saveDraft(currentState.review.id);
        emit(const AddBookReviewSuccess("Draft saved successfully"));
      } catch (e) {
        emit(AddBookReviewError(e.toString()));
        emit(AddBookReviewLoaded(currentState.review));
      }
    }
  }
}
