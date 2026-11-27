import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/upload_item.dart';
import '../repositories/uploads_repository.dart';

/// Delegates directly to the repository which already returns `Result<T>`.
class GetMyUploads implements UseCase<List<UploadItem>, NoParams> {
  final UploadsRepository repository;

  GetMyUploads(this.repository);

  @override
  Future<Result<List<UploadItem>>> call(NoParams params) =>
      repository.getMyUploads();
}
