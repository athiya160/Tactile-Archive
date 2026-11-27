import '../../../../core/usecases/usecase.dart';
import '../../../home/domain/entities/book.dart';
import '../repositories/favorites_repository.dart';

class WatchFavorites implements StreamUseCase<List<Book>, NoParams> {
  final FavoritesRepository repository;

  WatchFavorites(this.repository);

  @override
  Stream<List<Book>> call(NoParams params) {
    return repository.watchFavorites();
  }
}
