import 'package:equatable/equatable.dart';

abstract class BookOwnerDetailsEvent extends Equatable {
  const BookOwnerDetailsEvent();

  @override
  List<Object?> get props => [];
}

class BookOwnerDetailsStarted extends BookOwnerDetailsEvent {
  final String bookId;
  const BookOwnerDetailsStarted(this.bookId);

  @override
  List<Object?> get props => [bookId];
}

class BookOwnerDetailsEditPressed extends BookOwnerDetailsEvent {}

class BookOwnerDetailsDeletePressed extends BookOwnerDetailsEvent {}
