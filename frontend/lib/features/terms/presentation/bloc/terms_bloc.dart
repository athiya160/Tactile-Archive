import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_terms.dart';
import '../../domain/usecases/acknowledge_terms.dart';
import 'terms_event.dart';
import 'terms_state.dart';

class TermsBloc extends Bloc<TermsEvent, TermsState> {
  final GetTerms getTerms;
  final AcknowledgeTerms acknowledgeTerms;

  TermsBloc({required this.getTerms, required this.acknowledgeTerms})
    : super(TermsInitial()) {
    on<TermsStarted>(_onStarted);
    on<TermsAcknowledged>(_onAcknowledged);
  }

  Future<void> _onStarted(TermsStarted event, Emitter<TermsState> emit) async {
    emit(TermsLoading());
    final result = await getTerms(NoParams());
    result.fold(
      (failure) => emit(TermsError(failure.message)),
      (sections) => emit(TermsLoaded(sections: sections)),
    );
  }

  Future<void> _onAcknowledged(
    TermsAcknowledged event,
    Emitter<TermsState> emit,
  ) async {
    final result = await acknowledgeTerms(NoParams());
    result.fold(
      (failure) => emit(TermsError(failure.message)),
      (_) => emit(TermsAcknowledgeSuccess()),
    );
  }
}
