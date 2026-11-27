import 'dart:async';

import '../../../../core/services/api_service.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart';
import '../../../home/domain/entities/book.dart';
import '../../domain/repositories/favorites_repository.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final StreamController<List<Book>> _favoritesController =
      StreamController.broadcast();

  List<Book> _favorites = [];

  @override
  Future<Result<List<Book>>> getFavorites() async {
    try {
      final response = await ApiService.getFavorites();

      final books = response.map<Book>((json) {
        return Book(
          id: json['id'].toString(),
          title: json['title'] ?? '',
          author: json['author'] ?? '',
          description: json['description'] ?? '',
          coverUrl: json['image_url'] ?? '',
          rating: 4.5,
          price: 0,
          categories: [],
          listingType: ListingType.forSale,
          isFavorite: true,
        );
      }).toList();

      _favorites = books;
      _favoritesController.add(_favorites);

      return Result.success(books);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<Book>> watchFavorites() {
    return _favoritesController.stream;
  }

  @override
  Future<Result<void>> removeFavorite(String bookId) async {
    try {
      await ApiService.toggleFavorite(int.parse(bookId));

      _favorites.removeWhere((book) => book.id == bookId);
      _favoritesController.add(_favorites);

      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Set<String>> watchFavoriteIds() {
    return _favoritesController.stream.map(
      (books) => books.map((b) => b.id).toSet(),
    );
  }
}
