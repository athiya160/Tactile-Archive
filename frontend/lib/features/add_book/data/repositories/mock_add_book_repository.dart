import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart';
import '../../../home/domain/entities/book.dart';
import '../../domain/entities/listing_draft.dart';
import '../../domain/repositories/add_book_repository.dart';
import '../../../../core/services/api_service.dart';

class MockAddBookRepository implements AddBookRepository {
  ListingDraft _currentDraft = const ListingDraft();

  @override
  Future<Result<Book?>> lookupIsbn(String isbn) async {
    try {
      final cleanIsbn = isbn.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanIsbn.isEmpty) {
        return Result.failure(const ServerFailure('ISBN is empty'));
      }

      // 1. Google Books API Lookup
      final url = Uri.parse(
        'https://www.googleapis.com/books/v1/volumes?q=isbn:$cleanIsbn',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['totalItems'] != null &&
            data['totalItems'] > 0 &&
            data['items'] != null) {
          final item = data['items'][0];
          final volumeInfo = item['volumeInfo'] ?? {};
          final authors = volumeInfo['authors'] as List?;
          final categories = volumeInfo['categories'] as List?;

          var coverUrl = '';
          if (volumeInfo['imageLinks'] != null) {
            coverUrl = volumeInfo['imageLinks']['thumbnail'] ?? '';
            if (coverUrl.startsWith('http://')) {
              coverUrl = coverUrl.replaceFirst('http://', 'https://');
            }
          }

          final book = Book(
            id: 'isbn_$cleanIsbn',
            title: volumeInfo['title'] ?? 'Unknown Book',
            author: authors?.join(', ') ?? 'Unknown Author',
            coverUrl: coverUrl.trim().isNotEmpty
                ? coverUrl
                : '${ApiService.baseUrl}/images/book1.jpg',
            categories: categories != null
                ? List<String>.from(categories)
                : ['Fiction'],
            category: (categories != null && categories.isNotEmpty)
                ? categories.first.toString()
                : 'Fiction',
            listingType: ListingType.forSale,
            rating: (volumeInfo['averageRating'] as num?)?.toDouble() ?? 4.0,
            description:
                (volumeInfo['description']?.toString().trim().isNotEmpty ==
                    true)
                ? volumeInfo['description'].toString()
                : 'No description available for this archival record.',
            edition:
                (volumeInfo['publishedDate']?.toString().trim().isNotEmpty ==
                    true)
                ? volumeInfo['publishedDate'].toString()
                : '1st Edition',
            pages:
                (volumeInfo['pageCount']?.toString().trim().isNotEmpty == true)
                ? volumeInfo['pageCount'].toString()
                : '150',
            publisher:
                (volumeInfo['publisher']?.toString().trim().isNotEmpty == true)
                ? volumeInfo['publisher'].toString()
                : 'Unknown Publisher',
            language:
                (volumeInfo['language']?.toString().trim().isNotEmpty == true)
                ? volumeInfo['language'].toString().toUpperCase()
                : 'EN',
            isbn: cleanIsbn,
          );

          return Result.success(book);
        }
      }

      // 2. Open Library API Fallback
      final olUrl = Uri.parse(
        'https://openlibrary.org/api/books?bibkeys=ISBN:$cleanIsbn&format=json&jscmd=data',
      );
      final olResponse = await http.get(olUrl);
      if (olResponse.statusCode == 200) {
        final olData = jsonDecode(olResponse.body);
        final key = 'ISBN:$cleanIsbn';
        if (olData[key] != null) {
          final volumeInfo = olData[key];
          final authors = volumeInfo['authors'] as List?;
          final authorsText =
              authors?.map((a) => a['name']).join(', ') ?? 'Unknown Author';

          var coverUrl = '';
          if (volumeInfo['cover'] != null) {
            coverUrl =
                volumeInfo['cover']['large'] ??
                volumeInfo['cover']['medium'] ??
                '';
            if (coverUrl.startsWith('http://')) {
              coverUrl = coverUrl.replaceFirst('http://', 'https://');
            }
          }

          final book = Book(
            id: 'isbn_$cleanIsbn',
            title: volumeInfo['title'] ?? 'Unknown Book',
            author: authorsText,
            coverUrl: coverUrl.trim().isNotEmpty
                ? coverUrl
                : '${ApiService.baseUrl}/images/book2.jpg',
            categories: const ['Fiction'],
            category: 'Fiction',
            listingType: ListingType.forSale,
            rating: 4.0,
            description:
                (volumeInfo['notes']?.toString().trim().isNotEmpty == true)
                ? volumeInfo['notes'].toString()
                : 'No description available for this archival record.',
            edition:
                (volumeInfo['publish_date']?.toString().trim().isNotEmpty ==
                    true)
                ? volumeInfo['publish_date'].toString()
                : '1st Edition',
            pages:
                (volumeInfo['number_of_pages']?.toString().trim().isNotEmpty ==
                    true)
                ? volumeInfo['number_of_pages'].toString()
                : '150',
            publisher:
                (volumeInfo['publishers'] != null &&
                    volumeInfo['publishers'].isNotEmpty)
                ? volumeInfo['publishers'].map((p) => p['name']).join(', ')
                : 'Unknown Publisher',
            language: 'EN',
            isbn: cleanIsbn,
          );
          return Result.success(book);
        }
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure('ISBN Lookup Failed: $e'));
    }
  }

  @override
  Future<Result<ListingDraft>> createDraftFromBook(Book book) async {
    _currentDraft = ListingDraft(book: book, isbn: '978123');
    return Result.success(_currentDraft);
  }

  @override
  Future<Result<ListingDraft>> createEmptyDraft(String isbn) async {
    _currentDraft = ListingDraft(isbn: isbn);
    return Result.success(_currentDraft);
  }

  @override
  Future<Result<ListingDraft>> updateCategory(String category) async {
    _currentDraft = _currentDraft.copyWith(category: category);
    return Result.success(_currentDraft);
  }

  @override
  Future<Result<ListingDraft>> getCurrentDraft() async {
    return Result.success(_currentDraft);
  }
}
