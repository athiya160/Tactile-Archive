import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  final String id;
  final String bookId;
  final String title;
  final String author;
  final String coverUrl;
  final double price;
  final bool isPurchase;
  final int? rentalDays;
  final int quantity;

  const CartItem({
    required this.id,
    required this.bookId,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.price,
    this.isPurchase = true,
    this.rentalDays,
    this.quantity = 1,
  });

  /// Unit price represented in integer paise (1 INR = 100 paise)
  int get unitPricePaise => (price * 100).round();

  /// Total item price represented in integer paise
  int get totalItemPaise => unitPricePaise * quantity;

  @override
  List<Object?> get props => [
    id,
    bookId,
    title,
    author,
    coverUrl,
    price,
    isPurchase,
    rentalDays,
    quantity,
  ];

  CartItem copyWith({
    String? id,
    String? bookId,
    String? title,
    String? author,
    String? coverUrl,
    double? price,
    bool? isPurchase,
    int? rentalDays,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      price: price ?? this.price,
      isPurchase: isPurchase ?? this.isPurchase,
      rentalDays: rentalDays ?? this.rentalDays,
      quantity: quantity ?? this.quantity,
    );
  }
}
