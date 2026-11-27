import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/book.dart';
import '../repositories/catalog_repository.dart';

class GetCatalogBooksParams {
  final String? category;
  final String? sortBy;
  final int page;
  final int limit;
  final String? searchQuery;

  GetCatalogBooksParams({
    this.category,
    this.sortBy,
    this.page = 1,
    this.limit = 10,
    this.searchQuery,
  });
}

class GetCatalogBooks implements UseCase<List<Book>, GetCatalogBooksParams> {
  final CatalogRepository repository;

  GetCatalogBooks(this.repository);

  @override
  Future<Result<List<Book>>> call(GetCatalogBooksParams params) async {
    return await repository.getCatalog(
      category: params.category,
      sortBy: params.sortBy,
      page: params.page,
      limit: params.limit,
      searchQuery: params.searchQuery,
    );
  }
}
