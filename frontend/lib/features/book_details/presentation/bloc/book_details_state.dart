import 'package:equatable/equatable.dart';
import '../../../home/domain/entities/book.dart';

abstract class BookDetailsState extends Equatable {
  const BookDetailsState();

  @override
  List<Object?> get props => [];
}

class BookDetailsInitial extends BookDetailsState {}

class BookDetailsLoading extends BookDetailsState {}

class BookDetailsLoaded extends BookDetailsState {
  final Book book;
  final bool isFavorite;
  final String? successMessage;

  const BookDetailsLoaded({
    required this.book,
    this.isFavorite = false,
    this.successMessage,
  });

  @override
  List<Object?> get props => [book, isFavorite, successMessage];

  BookDetailsLoaded copyWith({
    Book? book,
    bool? isFavorite,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return BookDetailsLoaded(
      book: book ?? this.book,
      isFavorite: isFavorite ?? this.isFavorite,
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

class BookDetailsError extends BookDetailsState {
  final String message;
  const BookDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}
