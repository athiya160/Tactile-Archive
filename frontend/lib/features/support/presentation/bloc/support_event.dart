import 'package:equatable/equatable.dart';

abstract class SupportEvent extends Equatable {
  const SupportEvent();

  @override
  List<Object?> get props => [];
}

class SupportStarted extends SupportEvent {}

class SupportSearchQueryChanged extends SupportEvent {
  final String query;
  const SupportSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}
