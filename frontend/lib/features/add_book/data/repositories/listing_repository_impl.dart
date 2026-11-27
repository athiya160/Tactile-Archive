import '../../../../core/utils/result.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/book_copy.dart';
import '../../domain/entities/listing_draft.dart';
import '../../domain/repositories/listing_repository.dart';

class ListingRepositoryImpl implements ListingRepository {
  final ApiClient apiClient;

  ListingRepositoryImpl({required this.apiClient});

  @override
  Future<Result<void>> addCopy(BookCopy copy) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Result.success(null);
  }

  @override
  Future<Result<void>> removeCopy(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateCopy(BookCopy copy) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Result.success(null);
  }

  @override
  Future<Result<void>> finalizeListing(ListingDraft draft) async {
    try {
      final book = draft.book;
      if (book == null) {
        return Result.failure(const ServerFailure('No book metadata provided'));
      }

      final primaryCopy = draft.copies.isNotEmpty ? draft.copies.first : null;
      final price = primaryCopy?.price ?? 0.0;

      final List<String> images = [];
      for (final copy in draft.copies) {
        images.addAll(copy.imagePaths);
      }

      final body = {
        'title': book.title,
        'author': book.author,
        'description':
            '${book.description}\n\nNotes: ${draft.curatorialNotes ?? ""}\n\nPickup Address: ${draft.address ?? ""}'
                .trim(),
        'price': price,
        'category': draft.category ?? book.category,
        'cover_url': book.coverUrl,
        'publisher': book.publisher,
        'language': book.language,
        'isbn': book.isbn.isEmpty ? (draft.isbn ?? '') : book.isbn,
        'edition': book.edition,
        'pages': book.pages,
        'condition': primaryCopy?.condition.label ?? 'Good',
        'images': images,
      };

      await apiClient.postJson('/books', body: body);
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure('Failed to finalize listing: $e'));
    }
  }
}
