import 'package:equatable/equatable.dart';
import '../../domain/entities/listing_details.dart';

abstract class BookOwnerDetailsState extends Equatable {
  const BookOwnerDetailsState();

  @override
  List<Object?> get props => [];
}

class BookOwnerDetailsInitial extends BookOwnerDetailsState {}

class BookOwnerDetailsLoading extends BookOwnerDetailsState {}

class BookOwnerDetailsLoaded extends BookOwnerDetailsState {
  final ListingDetails listingDetails;
  final bool isDeleting;

  const BookOwnerDetailsLoaded(this.listingDetails, {this.isDeleting = false});

  BookOwnerDetailsLoaded copyWith({
    ListingDetails? listingDetails,
    bool? isDeleting,
  }) {
    return BookOwnerDetailsLoaded(
      listingDetails ?? this.listingDetails,
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }

  @override
  List<Object?> get props => [listingDetails, isDeleting];
}

class BookOwnerDetailsDeleteSuccess extends BookOwnerDetailsState {}

class BookOwnerDetailsError extends BookOwnerDetailsState {
  final String message;
  const BookOwnerDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}
