import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_listing_details.dart';
import '../../domain/usecases/edit_listing.dart';
import '../../domain/usecases/delete_listing.dart';
import 'book_owner_details_event.dart';
import 'book_owner_details_state.dart';

class BookOwnerDetailsBloc
    extends Bloc<BookOwnerDetailsEvent, BookOwnerDetailsState> {
  final GetListingDetails getListingDetails;
  final EditListing editListing;
  final DeleteListing deleteListing;

  BookOwnerDetailsBloc({
    required this.getListingDetails,
    required this.editListing,
    required this.deleteListing,
  }) : super(BookOwnerDetailsInitial()) {
    on<BookOwnerDetailsStarted>(_onStarted);
    on<BookOwnerDetailsEditPressed>(_onEditPressed);
    on<BookOwnerDetailsDeletePressed>(_onDeletePressed);
  }

  Future<void> _onStarted(
    BookOwnerDetailsStarted event,
    Emitter<BookOwnerDetailsState> emit,
  ) async {
    emit(BookOwnerDetailsLoading());
    final result = await getListingDetails(event.bookId);
    result.fold(
      (failure) => emit(BookOwnerDetailsError(failure.message)),
      (details) => emit(BookOwnerDetailsLoaded(details)),
    );
  }

  /// Initiates edit flow. In the current phase, navigates to /add-book.
  /// The result is not awaited — the router handles the navigation side-effect.
  Future<void> _onEditPressed(
    BookOwnerDetailsEditPressed event,
    Emitter<BookOwnerDetailsState> emit,
  ) async {
    if (state is! BookOwnerDetailsLoaded) return;
    final currentState = state as BookOwnerDetailsLoaded;

    final result = await editListing(currentState.listingDetails.book.id);
    result.fold((failure) => emit(BookOwnerDetailsError(failure.message)), (_) {
      // Navigation handled by the UI layer.
    });
  }

  Future<void> _onDeletePressed(
    BookOwnerDetailsDeletePressed event,
    Emitter<BookOwnerDetailsState> emit,
  ) async {
    if (state is! BookOwnerDetailsLoaded) return;
    final currentState = state as BookOwnerDetailsLoaded;

    // Show spinner on the button while deletion is in progress.
    emit(currentState.copyWith(isDeleting: true));

    final result = await deleteListing(currentState.listingDetails.book.id);
    result.fold(
      (failure) => emit(currentState.copyWith(isDeleting: false)),
      (_) => emit(BookOwnerDetailsDeleteSuccess()),
    );
  }
}
