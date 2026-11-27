import '../../../book_details/domain/repositories/book_repository.dart';
import '../../domain/entities/listing_details.dart';
import '../../domain/repositories/listing_repository.dart';
import '../../../../core/utils/result.dart';

/// C-3 Fix: No longer imports home/data/datasources/mock_catalog_datasource.dart.
/// Book data is fetched through BookRepository (the correct architectural path).
class ListingRepositoryImpl implements ListingRepository {
  final BookRepository bookRepository;

  ListingRepositoryImpl({required this.bookRepository});

  @override
  Future<Result<ListingDetails>> getListingDetails(String bookId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final bookResult = await bookRepository.getBookDetails(bookId);
    if (bookResult.isFailure) {
      return Result.failure(bookResult.failure!);
    } else {
      return Result.success(
        ListingDetails(
          book: bookResult.data!,
          isVerified: true,
          isActive: true,
        ),
      );
    }
  }

  @override
  Future<Result<void>> editListing(String bookId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // In production: navigate to edit form or call API.
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteListing(String bookId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // In production: call DELETE /listings/{bookId}.
    return Result.success(null);
  }
}
