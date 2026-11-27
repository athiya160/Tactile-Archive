import '../../../../core/usecases/usecase.dart';
import '../../domain/repositories/favorites_repository.dart';

/// Streams the set of favourite book IDs reactively.
/// Lives in the `favorites` domain — it is the correct home for this concern (C-5 fix).
/// `HomeBloc` depends on this use-case to efficiently badge book cards.
class WatchFavoriteIds implements StreamUseCase<Set<String>, NoParams> {
  final FavoritesRepository repository;

  WatchFavoriteIds(this.repository);

  @override
  Stream<Set<String>> call(NoParams params) {
    return repository.watchFavoriteIds();
  }
}
