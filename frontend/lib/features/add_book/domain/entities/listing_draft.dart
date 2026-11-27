import 'package:equatable/equatable.dart';
import '../../../home/domain/entities/book.dart';
import '../entities/book_copy.dart';

class ListingDraft extends Equatable {
  final Book? book;
  final String? category;
  final String? isbn;
  final List<BookCopy> copies;
  final String? curatorialNotes;
  final String? address;

  const ListingDraft({
    this.book,
    this.category,
    this.isbn,
    this.copies = const [],
    this.curatorialNotes,
    this.address,
  });

  ListingDraft copyWith({
    Book? book,
    String? category,
    String? isbn,
    List<BookCopy>? copies,
    String? curatorialNotes,
    String? address,
  }) {
    return ListingDraft(
      book: book ?? this.book,
      category: category ?? this.category,
      isbn: isbn ?? this.isbn,
      copies: copies ?? this.copies,
      curatorialNotes: curatorialNotes ?? this.curatorialNotes,
      address: address ?? this.address,
    );
  }

  bool get isCompleteStep1 => book != null;

  bool get isCompleteStep2 => copies.isNotEmpty;

  @override
  List<Object?> get props => [
    book,
    category,
    isbn,
    copies,
    curatorialNotes,
    address,
  ];
}
