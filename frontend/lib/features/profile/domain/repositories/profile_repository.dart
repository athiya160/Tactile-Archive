import '../entities/profile_summary.dart';

import '../../../../core/utils/result.dart';

abstract class ProfileRepository {
  Future<Result<ProfileSummary>> getProfileSummary();
}
