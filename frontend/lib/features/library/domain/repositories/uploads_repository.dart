import '../../../../core/utils/result.dart';

import '../entities/upload_item.dart';

abstract class UploadsRepository {
  Future<Result<List<UploadItem>>> getMyUploads();

  Future<Result<void>> deleteUpload(String id);
}
