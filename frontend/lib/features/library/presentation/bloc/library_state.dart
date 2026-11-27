import 'package:equatable/equatable.dart';
import '../../domain/entities/rental_item.dart';
import '../../domain/entities/upload_item.dart';

abstract class LibraryState extends Equatable {
  const LibraryState();

  @override
  List<Object?> get props => [];
}

class LibraryInitial extends LibraryState {}

class LibraryLoading extends LibraryState {}

class LibraryLoaded extends LibraryState {
  final List<RentalItem> rentals;
  final List<UploadItem> uploads;
  final int activeTabIndex;

  const LibraryLoaded({
    required this.rentals,
    required this.uploads,
    required this.activeTabIndex,
  });

  @override
  List<Object?> get props => [rentals, uploads, activeTabIndex];

  LibraryLoaded copyWith({
    List<RentalItem>? rentals,
    List<UploadItem>? uploads,
    int? activeTabIndex,
  }) {
    return LibraryLoaded(
      rentals: rentals ?? this.rentals,
      uploads: uploads ?? this.uploads,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
    );
  }
}

class LibraryError extends LibraryState {
  final String message;
  const LibraryError(this.message);

  @override
  List<Object?> get props => [message];
}
