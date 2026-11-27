import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/faq.dart';
import '../repositories/support_repository.dart';

class SearchFaqs implements UseCase<List<Faq>, String> {
  final SupportRepository repository;

  SearchFaqs(this.repository);

  @override
  Future<Result<List<Faq>>> call(String query) async {
    try {
      final faqs = await repository.searchFaqs(query);
      return Result.success(faqs);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}
