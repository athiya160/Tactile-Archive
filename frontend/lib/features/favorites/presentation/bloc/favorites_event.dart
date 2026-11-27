import 'package:equatable/equatable.dart';
import '../../../home/domain/entities/book.dart';

abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

class FavoritesStarted extends FavoritesEvent {}

class FavoritesRemovePressed extends FavoritesEvent {
  final String bookId;
  const FavoritesRemovePressed(this.bookId);

  @override
  List<Object?> get props => [bookId];
}

class FavoritesUpdated extends FavoritesEvent {
  final List<Book> favorites;
  const FavoritesUpdated(this.favorites);

  @override
  List<Object?> get props => [favorites];
}
