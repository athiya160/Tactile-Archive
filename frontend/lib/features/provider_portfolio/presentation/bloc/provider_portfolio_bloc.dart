import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/mock_catalog_datasource.dart';
import '../../../../core/services/api_service.dart';
import 'provider_portfolio_event.dart';
import 'provider_portfolio_state.dart';

class ProviderPortfolioBloc
    extends Bloc<ProviderPortfolioEvent, ProviderPortfolioState> {
  ProviderPortfolioBloc() : super(ProviderPortfolioInitial()) {
    on<ProviderPortfolioStarted>(_onStarted);
  }

  Future<void> _onStarted(
    ProviderPortfolioStarted event,
    Emitter<ProviderPortfolioState> emit,
  ) async {
    emit(ProviderPortfolioLoading());
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 600));

      final allBooks = MockCatalogDataSource.books;
      // For demonstration, pick a few books to act as the provider's uploaded books
      final providerBooks = allBooks.take(6).toList();

      final providerName = ApiService.userName ?? "Virginia Burton";

      if (providerBooks.isEmpty) {
        emit(const ProviderPortfolioError("No books found."));
      } else {
        emit(
          ProviderPortfolioLoaded(
            providerName: providerName,
            featuredBook: providerBooks.first,
            books: providerBooks,
          ),
        );
      }
    } catch (e) {
      emit(ProviderPortfolioError(e.toString()));
    }
  }
}
