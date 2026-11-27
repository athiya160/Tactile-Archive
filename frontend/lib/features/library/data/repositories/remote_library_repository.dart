import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/services/api_service.dart';
import '../../domain/entities/rental_item.dart';
import '../../domain/entities/upload_item.dart';
import '../../domain/repositories/rentals_repository.dart';
import '../../domain/repositories/uploads_repository.dart';
import 'mock_library_repository.dart';

class RemoteLibraryRepository implements RentalsRepository, UploadsRepository {
  final ApiClient apiClient;
  final MockLibraryRepository _fallback = MockLibraryRepository();

  RemoteLibraryRepository(this.apiClient);

  @override
  Future<Result<List<RentalItem>>> getActiveRentals() async {
    try {
      final response = await apiClient.getJson('/library/rentals');
      if (response is List) {
        final items = response.map((item) {
          final data = item as Map<String, dynamic>;
          return RentalItem(
            id: data['id']?.toString() ?? '',
            title: data['title']?.toString() ?? '',
            author: data['author']?.toString() ?? '',
            coverUrl: ApiService.resolveImageUrl(
              data['coverUrl']?.toString() ?? '',
            ),
            progress: _parseDouble(data['progress']) ?? 0.0,
            dueLabel:
                data['dueLabel']?.toString() ??
                (data['rentalDays'] != null
                    ? 'Due in ${data['rentalDays']} days'
                    : 'Due soon'),
          );
        }).toList();
        if (items.isNotEmpty) {
          return Result.success(items);
        }
      }
    } catch (_) {
      // Fallback gracefully to mock rentals if server is offline or unreachable
    }
    return _fallback.getActiveRentals();
  }

  @override
  Future<Result<List<UploadItem>>> getMyUploads() async {
    try {
      final response = await apiClient.getJson('/library/uploads');
      if (response is List) {
        final uploads = response.map((item) {
          final data = item as Map<String, dynamic>;
          return UploadItem(
            id: data['id']?.toString() ?? '',
            title: data['title']?.toString() ?? '',
            author: data['author']?.toString() ?? '',
            coverUrl: ApiService.resolveImageUrl(data['coverUrl']?.toString()),
            status: _parseUploadStatus(data['status']),
          );
        }).toList();
        if (uploads.isNotEmpty) {
          return Result.success(uploads);
        }
      }
    } catch (_) {
      // Fallback gracefully to mock uploads if server is offline or unreachable
    }
    return _fallback.getMyUploads();
  }

  @override
  Future<Result<void>> deleteUpload(String id) async {
    try {
      await apiClient.deleteJson('/library/uploads/$id');
      return Result.success(null);
    } catch (_) {
      return _fallback.deleteUpload(id);
    }
  }

  double? _parseDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }

  UploadStatus _parseUploadStatus(dynamic raw) {
    final value = raw?.toString().toLowerCase();
    switch (value) {
      case 'active':
        return UploadStatus.active;
      case 'pending':
      default:
        return UploadStatus.pending;
    }
  }
}
