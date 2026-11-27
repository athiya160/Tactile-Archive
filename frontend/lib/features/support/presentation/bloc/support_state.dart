import 'package:equatable/equatable.dart';
import '../../domain/entities/faq.dart';

abstract class SupportState extends Equatable {
  const SupportState();

  @override
  List<Object?> get props => [];
}

class SupportInitial extends SupportState {}

class SupportLoading extends SupportState {}

class SupportLoaded extends SupportState {
  final List<Faq> faqs;
  final String query;

  const SupportLoaded({required this.faqs, this.query = ''});

  @override
  List<Object?> get props => [faqs, query];
}

class SupportError extends SupportState {
  final String message;
  const SupportError(this.message);

  @override
  List<Object?> get props => [message];
}
