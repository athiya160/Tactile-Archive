import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/favorites_repository.dart';

class RemoveFavorite implements UseCase<void, String> {
  final FavoritesRepository repository;

  RemoveFavorite(this.repository);

  @override
  Future<Result<void>> call(String bookId) async {
    return await repository.removeFavorite(bookId);
  }
}
