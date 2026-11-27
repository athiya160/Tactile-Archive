import 'package:equatable/equatable.dart';
import 'package:libri_flow/core/services/api_service.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

class OnboardingPersonaSelected extends OnboardingEvent {
  final UserType persona;

  const OnboardingPersonaSelected(this.persona);

  @override
  List<Object?> get props => [persona];
}

class OnboardingSubmitted extends OnboardingEvent {
  const OnboardingSubmitted();
}
