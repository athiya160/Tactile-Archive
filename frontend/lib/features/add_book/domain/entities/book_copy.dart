import 'package:equatable/equatable.dart';

enum BookCondition {
  newCondition('New'),
  likeNew('Like New'),
  good('Good'),
  fair('Fair'),
  poor('Poor');

  final String label;
  const BookCondition(this.label);
}

enum ListingType {
  sell('Sell'),
  rent('Rent'),
  donate('Donate');

  final String label;
  const ListingType(this.label);
}

class BookCopy extends Equatable {
  final String id;
  final BookCondition condition;
  final ListingType listingType;
  final double? price;
  final String? notes;
  final List<String> imagePaths;

  const BookCopy({
    required this.id,
    this.condition = BookCondition.good,
    this.listingType = ListingType.sell,
    this.price,
    this.notes,
    this.imagePaths = const [],
  });

  BookCopy copyWith({
    String? id,
    BookCondition? condition,
    ListingType? listingType,
    double? price,
    String? notes,
    List<String>? imagePaths,
  }) {
    return BookCopy(
      id: id ?? this.id,
      condition: condition ?? this.condition,
      listingType: listingType ?? this.listingType,
      price: price ?? this.price,
      notes: notes ?? this.notes,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }

  @override
  List<Object?> get props => [
    id,
    condition,
    listingType,
    price,
    notes,
    imagePaths,
  ];
}
