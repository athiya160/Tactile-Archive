import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/catalog_repository.dart';

class GetCategories implements UseCase<List<String>, NoParams> {
  final CatalogRepository repository;

  GetCategories(this.repository);

  @override
  Future<Result<List<String>>> call(NoParams params) async {
    return await repository.getCategories();
  }
}
