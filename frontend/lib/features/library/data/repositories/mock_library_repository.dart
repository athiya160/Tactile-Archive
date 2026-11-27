import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/rental_item.dart';
import '../../domain/entities/upload_item.dart';
import '../../domain/repositories/rentals_repository.dart';
import '../../domain/repositories/uploads_repository.dart';

class MockLibraryRepository implements RentalsRepository, UploadsRepository {
  // Mutable in-memory list so that deleteUpload actually removes items.
  final List<UploadItem> _uploads = [
    const UploadItem(
      id: '101',
      title: 'Notes from Underground',
      author: 'Fyodor Dostoevsky',
      coverUrl: 'assets/books/notes_from_underground.jpg',
      status: UploadStatus.active,
    ),
    const UploadItem(
      id: '102',
      title: 'Meditations',
      author: 'Marcus Aurelius',
      coverUrl: 'assets/books/meditations.jpg',
      status: UploadStatus.pending,
    ),
    const UploadItem(
      id: '103',
      title: 'Circe',
      author: 'Madeline Miller',
      coverUrl: 'assets/books/circe.jpg',
      status: UploadStatus.active,
    ),
  ];

  static const List<RentalItem> _defaultRentals = [
    RentalItem(
      id: '1',
      title: 'The Alchemist',
      author: 'Paulo Coelho',
      coverUrl: 'assets/books/the_alchemist.jpg',
      progress: 0.64,
      dueLabel: 'Due in 2d',
    ),
    RentalItem(
      id: '2',
      title: 'A Moveable Feast',
      author: 'Ernest Hemingway',
      coverUrl: 'assets/books/a_moveable_feast.jpg',
      progress: 0.12,
      dueLabel: 'Oct 24',
    ),
    RentalItem(
      id: '3',
      title: 'Kafka on the Shore',
      author: 'Haruki Murakami',
      coverUrl: 'assets/books/kafka_on_the_shore.jpg',
      progress: 0.85,
      dueLabel: 'Due tomorrow',
    ),
  ];

  @override
  Future<Result<List<RentalItem>>> getActiveRentals() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return Result.success(List.unmodifiable(_defaultRentals));
  }

  @override
  Future<Result<List<UploadItem>>> getMyUploads() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return Result.success(List.unmodifiable(_uploads));
  }

  @override
  Future<Result<void>> deleteUpload(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _uploads.indexWhere((u) => u.id == id);
    if (index == -1) {
      return Result.failure(const ServerFailure('Upload not found'));
    }
    _uploads.removeAt(index);
    return Result.success(null);
  }
}
