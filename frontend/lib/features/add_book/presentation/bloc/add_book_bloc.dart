import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../home/domain/entities/book.dart';
import '../../domain/entities/listing_draft.dart';
import '../../domain/entities/book_copy.dart' as copy;
import '../../domain/usecases/lookup_isbn.dart';
import '../../domain/usecases/create_draft.dart';
import '../../domain/usecases/update_category.dart';

// --- Events ---
abstract class AddBookEvent {}

class AddBookIsbnChanged extends AddBookEvent {
  final String isbn;
  AddBookIsbnChanged(this.isbn);
}

class AddBookLookupRequested extends AddBookEvent {}

class AddBookCategorySelected extends AddBookEvent {
  final String category;
  AddBookCategorySelected(this.category);
}

class AddBookManualEntryRequested extends AddBookEvent {}

class AddBookManualBookSubmitted extends AddBookEvent {
  final String title;
  final String author;
  final String description;
  final String category;
  final String publisher;
  final String year;
  final String pages;
  final String language;
  final String isbn;
  final double price;
  final copy.BookCondition condition;
  final String coverUrl;

  AddBookManualBookSubmitted({
    required this.title,
    required this.author,
    required this.description,
    required this.category,
    required this.publisher,
    required this.year,
    required this.pages,
    required this.language,
    required this.isbn,
    required this.price,
    required this.condition,
    required this.coverUrl,
  });
}

class AddBookReset extends AddBookEvent {}

// --- States ---
enum AddBookStatus { initial, loading, found, notFound, error }

class AddBookState {
  final String isbn;
  final ListingDraft draft;
  final AddBookStatus status;
  final String? errorMessage;

  const AddBookState({
    this.isbn = '',
    this.draft = const ListingDraft(),
    this.status = AddBookStatus.initial,
    this.errorMessage,
  });

  AddBookState copyWith({
    String? isbn,
    ListingDraft? draft,
    AddBookStatus? status,
    String? errorMessage,
  }) {
    return AddBookState(
      isbn: isbn ?? this.isbn,
      draft: draft ?? this.draft,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// --- Bloc ---
class AddBookBloc extends Bloc<AddBookEvent, AddBookState> {
  final LookupIsbn lookupIsbn;
  final CreateDraft createDraft;
  final UpdateCategory updateCategory;

  AddBookBloc({
    required this.lookupIsbn,
    required this.createDraft,
    required this.updateCategory,
  }) : super(const AddBookState()) {
    on<AddBookIsbnChanged>(_onIsbnChanged);
    on<AddBookLookupRequested>(_onLookupRequested);
    on<AddBookCategorySelected>(_onCategorySelected);
    on<AddBookManualEntryRequested>(_onManualEntryRequested);
    on<AddBookManualBookSubmitted>(_onManualBookSubmitted);
    on<AddBookReset>((_, emit) => emit(const AddBookState()));
  }

  void _onIsbnChanged(AddBookIsbnChanged event, Emitter<AddBookState> emit) {
    emit(state.copyWith(isbn: event.isbn, status: AddBookStatus.initial));
  }

  Future<void> _onLookupRequested(
    AddBookLookupRequested event,
    Emitter<AddBookState> emit,
  ) async {
    if (state.isbn.isEmpty) return;

    emit(state.copyWith(status: AddBookStatus.loading));

    final result = await lookupIsbn(state.isbn);

    if (result.isFailure) {
      emit(
        state.copyWith(
          status: AddBookStatus.error,
          errorMessage: result.failure?.message,
        ),
      );
      return;
    }

    final book = result.data;
    if (book != null) {
      final draftResult = await createDraft.fromBook(book);

      if (draftResult.isFailure) {
        emit(
          state.copyWith(
            status: AddBookStatus.error,
            errorMessage: draftResult.failure?.message,
          ),
        );
      } else {
        emit(
          state.copyWith(status: AddBookStatus.found, draft: draftResult.data),
        );
      }
    } else {
      emit(state.copyWith(status: AddBookStatus.notFound));
    }
  }

  Future<void> _onCategorySelected(
    AddBookCategorySelected event,
    Emitter<AddBookState> emit,
  ) async {
    final result = await updateCategory(event.category);
    if (result.isFailure) {
      emit(
        state.copyWith(
          status: AddBookStatus.error,
          errorMessage: result.failure?.message,
        ),
      );
    } else {
      emit(state.copyWith(draft: result.data));
    }
  }

  Future<void> _onManualEntryRequested(
    AddBookManualEntryRequested event,
    Emitter<AddBookState> emit,
  ) async {
    final result = await createDraft.empty(state.isbn);
    if (result.isFailure) {
      emit(
        state.copyWith(
          status: AddBookStatus.error,
          errorMessage: result.failure?.message,
        ),
      );
    }
  }

  Future<void> _onManualBookSubmitted(
    AddBookManualBookSubmitted event,
    Emitter<AddBookState> emit,
  ) async {
    final manualBook = Book(
      id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      title: event.title,
      author: event.author,
      description: event.description,
      categories: [event.category],
      publisher: event.publisher,
      edition: event.year,
      pages: event.pages,
      language: event.language,
      isbn: event.isbn,
      coverUrl: event.coverUrl,
      listingType: ListingType.forSale,
      rating: 0,
    );

    final defaultCopy = copy.BookCopy(
      id: 'copy_${DateTime.now().millisecondsSinceEpoch}',
      condition: event.condition,
      listingType: copy.ListingType.sell,
      price: event.price,
    );

    final updatedDraft = state.draft.copyWith(
      book: manualBook,
      category: event.category,
      isbn: event.isbn,
      copies: [defaultCopy],
    );

    emit(state.copyWith(draft: updatedDraft));
  }
}
