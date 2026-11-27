import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/settings_entity.dart';
import '../repositories/settings_repository.dart';

class UpdateSettings implements UseCase<void, SettingsEntity> {
  final SettingsRepository repository;

  UpdateSettings(this.repository);

  @override
  Future<Result<void>> call(SettingsEntity settings) async {
    try {
      await repository.updateSettings(settings);
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}
