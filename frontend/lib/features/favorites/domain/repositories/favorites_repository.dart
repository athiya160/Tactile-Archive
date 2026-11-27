import '../../../../core/utils/result.dart';
import '../../../home/domain/entities/book.dart';

abstract class FavoritesRepository {
  Future<Result<List<Book>>> getFavorites();
  Stream<List<Book>> watchFavorites();
  Future<Result<void>> removeFavorite(String bookId);

  /// Streams just the set of favourite book IDs.
  /// Used by HomeBloc for efficient per-card favourite badge updates.
  Stream<Set<String>> watchFavoriteIds();
}
