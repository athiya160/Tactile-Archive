import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libri_flow/core/services/api_service.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(const OnboardingState()) {
    on<OnboardingPersonaSelected>(_onPersonaSelected);
    on<OnboardingSubmitted>(_onSubmitted);
  }

  void _onPersonaSelected(
    OnboardingPersonaSelected event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(selectedPersona: event.persona, errorMessage: null));
  }

  Future<void> _onSubmitted(
    OnboardingSubmitted event,
    Emitter<OnboardingState> emit,
  ) async {
    if (state.selectedPersona == null) {
      emit(state.copyWith(errorMessage: 'Please select an experience to continue.'));
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: null));

    final success = await ApiService.updateUserPersona(state.selectedPersona!);

    if (success) {
      emit(state.copyWith(isLoading: false, isSuccess: true));
    } else {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save experience selection. Please try again.',
      ));
    }
  }
}
