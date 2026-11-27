import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/uploads_repository.dart';

/// Delegates directly to the repository which owns the `Result<void>` contract.
class DeleteUpload implements UseCase<void, String> {
  final UploadsRepository repository;

  DeleteUpload(this.repository);

  @override
  Future<Result<void>> call(String id) => repository.deleteUpload(id);
}
