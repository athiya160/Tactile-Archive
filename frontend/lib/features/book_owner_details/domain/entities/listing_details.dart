import '../../../home/domain/entities/book.dart';

class ListingDetails {
  final Book book;
  final bool isVerified;
  final bool isActive;

  const ListingDetails({
    required this.book,
    required this.isVerified,
    required this.isActive,
  });

  ListingDetails copyWith({Book? book, bool? isVerified, bool? isActive}) {
    return ListingDetails(
      book: book ?? this.book,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
    );
  }
}
