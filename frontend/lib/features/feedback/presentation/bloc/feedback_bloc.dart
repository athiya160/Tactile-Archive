import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/submit_feedback.dart';
import 'feedback_event.dart';
import 'feedback_state.dart';

class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  final SubmitFeedback submitFeedback;

  FeedbackBloc({required this.submitFeedback}) : super(const FeedbackState()) {
    on<FeedbackStarted>(_onStarted);
    on<FeedbackRatingChanged>(_onRatingChanged);
    on<FeedbackReasonChanged>(_onReasonChanged);
    on<FeedbackCommentsChanged>(_onCommentsChanged);
    on<FeedbackSubmitted>(_onSubmitted);
  }

  void _onStarted(FeedbackStarted event, Emitter<FeedbackState> emit) {
    // Form initialized with default state; no async work needed
    emit(state); // Ensures state is emitted
  }

  void _onRatingChanged(
    FeedbackRatingChanged event,
    Emitter<FeedbackState> emit,
  ) {
    emit(
      state.copyWith(feedback: state.feedback.copyWith(rating: event.rating)),
    );
  }

  void _onReasonChanged(
    FeedbackReasonChanged event,
    Emitter<FeedbackState> emit,
  ) {
    emit(
      state.copyWith(feedback: state.feedback.copyWith(reason: event.reason)),
    );
  }

  void _onCommentsChanged(
    FeedbackCommentsChanged event,
    Emitter<FeedbackState> emit,
  ) {
    emit(
      state.copyWith(
        feedback: state.feedback.copyWith(comments: event.comments),
      ),
    );
  }

  Future<void> _onSubmitted(
    FeedbackSubmitted event,
    Emitter<FeedbackState> emit,
  ) async {
    if (state.feedback.rating == 0) {
      emit(
        state.copyWith(
          status: FeedbackStatus.failure,
          errorMessage: 'Please select a rating before submitting.',
        ),
      );
      return;
    }

    if (state.feedback.comments.isEmpty) {
      emit(
        state.copyWith(
          status: FeedbackStatus.failure,
          errorMessage: 'Please provide some detailed thoughts.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: FeedbackStatus.loading));

    final result = await submitFeedback(state.feedback);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: FeedbackStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(state.copyWith(status: FeedbackStatus.success)),
    );
  }
}
