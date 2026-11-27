import '../../../../core/utils/result.dart';
import '../repositories/book_repository.dart';

class ToggleFavorite {
  final BookRepository repository;

  ToggleFavorite(this.repository);

  Future<Result<bool>> call(String id) async {
    return await repository.toggleFavorite(id);
  }
}
