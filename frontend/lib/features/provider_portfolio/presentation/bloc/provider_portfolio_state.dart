import 'package:equatable/equatable.dart';
import '../../../home/domain/entities/book.dart';

abstract class ProviderPortfolioState extends Equatable {
  const ProviderPortfolioState();

  @override
  List<Object?> get props => [];
}

class ProviderPortfolioInitial extends ProviderPortfolioState {}

class ProviderPortfolioLoading extends ProviderPortfolioState {}

class ProviderPortfolioLoaded extends ProviderPortfolioState {
  final String providerName;
  final Book featuredBook;
  final List<Book> books;

  const ProviderPortfolioLoaded({
    required this.providerName,
    required this.featuredBook,
    required this.books,
  });

  @override
  List<Object?> get props => [providerName, featuredBook, books];
}

class ProviderPortfolioError extends ProviderPortfolioState {
  final String message;

  const ProviderPortfolioError(this.message);

  @override
  List<Object?> get props => [message];
}
