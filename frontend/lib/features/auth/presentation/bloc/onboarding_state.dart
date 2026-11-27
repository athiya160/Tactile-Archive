import 'package:equatable/equatable.dart';
import 'package:libri_flow/core/services/api_service.dart';

class OnboardingState extends Equatable {
  final UserType? selectedPersona;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const OnboardingState({
    this.selectedPersona,
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  OnboardingState copyWith({
    UserType? selectedPersona,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return OnboardingState(
      selectedPersona: selectedPersona ?? this.selectedPersona,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [selectedPersona, isLoading, errorMessage, isSuccess];
}
