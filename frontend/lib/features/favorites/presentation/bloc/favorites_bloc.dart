import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_favorites.dart';
import '../../domain/usecases/watch_favorites.dart';
import '../../domain/usecases/remove_favorite.dart';
import 'favorites_event.dart';
import 'favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final GetFavorites getFavorites;
  final WatchFavorites watchFavorites;
  final RemoveFavorite removeFavorite;
  StreamSubscription? _favoritesSubscription;

  FavoritesBloc({
    required this.getFavorites,
    required this.watchFavorites,
    required this.removeFavorite,
  }) : super(FavoritesInitial()) {
    on<FavoritesStarted>(_onStarted);
    on<FavoritesRemovePressed>(_onRemovePressed);
    on<FavoritesUpdated>(_onUpdated);

    _favoritesSubscription = watchFavorites(NoParams()).listen((favorites) {
      if (!isClosed) {
        add(FavoritesUpdated(favorites));
      }
    });
  }

  @override
  Future<void> close() {
    _favoritesSubscription?.cancel();
    return super.close();
  }

  void _onUpdated(FavoritesUpdated event, Emitter<FavoritesState> emit) {
    emit(FavoritesLoaded(event.favorites));
  }

  Future<void> _onStarted(
    FavoritesStarted event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(FavoritesLoading());
    final result = await getFavorites(NoParams());
    result.fold(
      (error) => emit(FavoritesError(error.message)),
      (favorites) => emit(FavoritesLoaded(favorites)),
    );
  }

  Future<void> _onRemovePressed(
    FavoritesRemovePressed event,
    Emitter<FavoritesState> emit,
  ) async {
    final currentState = state;
    if (currentState is FavoritesLoaded) {
      // Optimistic update
      final newFavorites = currentState.favorites
          .where((book) => book.id != event.bookId)
          .toList();
      emit(FavoritesLoaded(newFavorites));

      final result = await removeFavorite(event.bookId);
      result.fold(
        (error) {
          // Revert on failure
          emit(FavoritesError(error.message));
          emit(FavoritesLoaded(currentState.favorites));
        },
        (_) {}, // Already updated
      );
    }
  }
}
