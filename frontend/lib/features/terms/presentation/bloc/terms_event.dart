import 'package:equatable/equatable.dart';

abstract class TermsEvent extends Equatable {
  const TermsEvent();

  @override
  List<Object> get props => [];
}

class TermsStarted extends TermsEvent {}

class TermsAcknowledged extends TermsEvent {}
