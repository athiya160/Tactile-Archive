import 'package:equatable/equatable.dart';

abstract class ProviderPortfolioEvent extends Equatable {
  const ProviderPortfolioEvent();

  @override
  List<Object?> get props => [];
}

class ProviderPortfolioStarted extends ProviderPortfolioEvent {}
