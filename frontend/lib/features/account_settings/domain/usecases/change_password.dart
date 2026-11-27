import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/settings_repository.dart';
import 'package:equatable/equatable.dart';

class ChangePassword implements UseCase<void, ChangePasswordParams> {
  final SettingsRepository repository;

  ChangePassword(this.repository);

  @override
  Future<Result<void>> call(ChangePasswordParams params) async {
    try {
      await repository.changePassword(
        params.currentPassword,
        params.newPassword,
        params.confirmPassword,
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}

class ChangePasswordParams extends Equatable {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  const ChangePasswordParams({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword, confirmPassword];
}
