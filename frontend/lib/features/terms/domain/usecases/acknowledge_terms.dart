import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/terms_repository.dart';

class AcknowledgeTerms implements UseCase<void, NoParams> {
  final TermsRepository repository;

  AcknowledgeTerms(this.repository);

  @override
  Future<Result<void>> call(NoParams params) async {
    await repository.acknowledgeTerms();
    return Result.success(null);
  }
}
