import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/settings_entity.dart';
import '../repositories/settings_repository.dart';

class GetSettings implements UseCase<SettingsEntity, NoParams> {
  final SettingsRepository repository;

  GetSettings(this.repository);

  @override
  Future<Result<SettingsEntity>> call(NoParams params) async {
    try {
      final settings = await repository.getSettings();
      return Result.success(settings);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}
