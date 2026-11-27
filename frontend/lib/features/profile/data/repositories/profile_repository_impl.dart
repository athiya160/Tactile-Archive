import '../../../../core/services/api_service.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/profile_summary.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  @override
  Future<Result<ProfileSummary>> getProfileSummary() async {
    try {
      final data = await ApiService.getProfile();
      return Result.success(
        ProfileSummary(
          name: data['name'] ?? '',
          level: data['level'] ?? '',
          avatarUrl: data['avatarUrl'] ?? '',
          booksBorrowedCount: data['booksBorrowedCount'] ?? 0,
          booksSharedCount: data['booksSharedCount'] ?? 0,
          isAdmin: data['is_admin'] == true || data['isAdmin'] == true,
        ),
      );
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}
