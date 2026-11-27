import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_faqs.dart';
import '../../domain/usecases/search_faqs.dart';
import 'support_event.dart';
import 'support_state.dart';

class SupportBloc extends Bloc<SupportEvent, SupportState> {
  final GetFaqs getFaqs;
  final SearchFaqs searchFaqs;

  SupportBloc({required this.getFaqs, required this.searchFaqs})
    : super(SupportInitial()) {
    on<SupportStarted>(_onStarted);
    on<SupportSearchQueryChanged>(_onSearchQueryChanged);
  }

  Future<void> _onStarted(
    SupportStarted event,
    Emitter<SupportState> emit,
  ) async {
    emit(SupportLoading());
    final result = await getFaqs(NoParams());
    result.fold(
      (failure) => emit(SupportError(failure.message)),
      (faqs) => emit(SupportLoaded(faqs: faqs)),
    );
  }

  Future<void> _onSearchQueryChanged(
    SupportSearchQueryChanged event,
    Emitter<SupportState> emit,
  ) async {
    final currentState = state;
    if (currentState is SupportLoaded) {
      final result = await searchFaqs(event.query);
      result.fold(
        (failure) => emit(SupportError(failure.message)),
        (faqs) => emit(SupportLoaded(faqs: faqs, query: event.query)),
      );
    }
  }
}
