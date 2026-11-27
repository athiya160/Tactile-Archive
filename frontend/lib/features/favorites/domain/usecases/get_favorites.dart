import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../home/domain/entities/book.dart';
import '../repositories/favorites_repository.dart';

class GetFavorites implements UseCase<List<Book>, NoParams> {
  final FavoritesRepository repository;

  GetFavorites(this.repository);

  @override
  Future<Result<List<Book>>> call(NoParams params) async {
    return await repository.getFavorites();
  }
}
