import 'package:equatable/equatable.dart';
import '../../domain/entities/terms_section.dart';

abstract class TermsState extends Equatable {
  const TermsState();

  @override
  List<Object?> get props => [];
}

class TermsInitial extends TermsState {}

class TermsLoading extends TermsState {}

class TermsLoaded extends TermsState {
  final List<TermsSection> sections;
  final String lastUpdated;

  const TermsLoaded({
    required this.sections,
    this.lastUpdated = 'October 24, 2023',
  });

  @override
  List<Object?> get props => [sections, lastUpdated];
}

class TermsError extends TermsState {
  final String message;

  const TermsError(this.message);

  @override
  List<Object?> get props => [message];
}

class TermsAcknowledgeSuccess extends TermsState {}
