import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/settings_repository.dart';
import 'package:equatable/equatable.dart';

class UploadAvatar implements UseCase<String, UploadAvatarParams> {
  final SettingsRepository repository;

  UploadAvatar(this.repository);

  @override
  Future<Result<String>> call(UploadAvatarParams params) async {
    try {
      final url = await repository.uploadAvatar(params.imagePath);
      return Result.success(url);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}

class UploadAvatarParams extends Equatable {
  final String imagePath;

  const UploadAvatarParams(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}
