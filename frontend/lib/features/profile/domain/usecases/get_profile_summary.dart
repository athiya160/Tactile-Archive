import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/profile_summary.dart';
import '../repositories/profile_repository.dart';

class GetProfileSummary implements UseCase<ProfileSummary, NoParams> {
  final ProfileRepository repository;

  GetProfileSummary(this.repository);

  @override
  Future<Result<ProfileSummary>> call(NoParams params) async {
    return await repository.getProfileSummary();
  }
}
