import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/services/api_service.dart';
import '../../domain/entities/profile_summary.dart';
import '../../domain/repositories/profile_repository.dart';
import 'mock_profile_repository.dart';

class RemoteProfileRepository implements ProfileRepository {
  final ApiClient apiClient;
  final MockProfileRepository _fallback = MockProfileRepository();

  RemoteProfileRepository(this.apiClient);

  @override
  Future<Result<ProfileSummary>> getProfileSummary() async {
    try {
      final response = await apiClient.getJson('/profile/summary');
      if (response is Map<String, dynamic>) {
        return Result.success(
          ProfileSummary(
            name: response['name']?.toString() ?? (ApiService.userName ?? 'Julian Thorne'),
            level: response['level']?.toString() ?? 'Curator Level Reader',
            avatarUrl: response['avatarUrl']?.toString() ?? '',
            booksBorrowedCount: response['booksBorrowedCount'] is int
                ? response['booksBorrowedCount'] as int
                : int.tryParse(
                        response['booksBorrowedCount']?.toString() ?? '0',
                      ) ??
                      0,
            booksSharedCount: response['booksSharedCount'] is int
                ? response['booksSharedCount'] as int
                : int.tryParse(
                        response['booksSharedCount']?.toString() ?? '0',
                      ) ??
                      0,
            isAdmin: response['is_admin'] == true,
          ),
        );
      }
    } catch (_) {
      // Fallback gracefully to mock profile when offline
    }
    return _fallback.getProfileSummary();
  }
}
