import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/book.dart';
import '../repositories/catalog_repository.dart';

class GetFeaturedBooks implements UseCase<List<Book>, NoParams> {
  final CatalogRepository repository;

  GetFeaturedBooks(this.repository);

  @override
  Future<Result<List<Book>>> call(NoParams params) async {
    return await repository.getFeatured();
  }
}
