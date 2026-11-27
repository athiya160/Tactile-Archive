import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/terms_repository.dart';
import '../entities/terms_section.dart';

class GetTerms implements UseCase<List<TermsSection>, NoParams> {
  final TermsRepository repository;

  GetTerms(this.repository);

  @override
  Future<Result<List<TermsSection>>> call(NoParams params) async {
    final terms = await repository.getTerms();
    return Result.success(terms);
  }
}
