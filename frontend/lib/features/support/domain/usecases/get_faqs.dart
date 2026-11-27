import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/faq.dart';
import '../repositories/support_repository.dart';

class GetFaqs implements UseCase<List<Faq>, NoParams> {
  final SupportRepository repository;

  GetFaqs(this.repository);

  @override
  Future<Result<List<Faq>>> call(NoParams params) async {
    try {
      final faqs = await repository.getFaqs();
      return Result.success(faqs);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}
