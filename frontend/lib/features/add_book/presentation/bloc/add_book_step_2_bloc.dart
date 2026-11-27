import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/listing_draft.dart';
import '../../domain/entities/book_copy.dart';
import '../../domain/repositories/listing_repository.dart';

// --- Events ---
abstract class AddBookStep2Event {}

class AddBookStep2InitialDraftLoaded extends AddBookStep2Event {
  final ListingDraft draft;
  AddBookStep2InitialDraftLoaded(this.draft);
}

class AddBookStep2AddCopyPressed extends AddBookStep2Event {}

class AddBookStep2RemoveCopyPressed extends AddBookStep2Event {
  final String copyId;
  AddBookStep2RemoveCopyPressed(this.copyId);
}

class AddBookStep2CopyUpdated extends AddBookStep2Event {
  final BookCopy copy;
  AddBookStep2CopyUpdated(this.copy);
}

class AddBookStep2CopyExpansionToggled extends AddBookStep2Event {
  final String copyId;
  AddBookStep2CopyExpansionToggled(this.copyId);
}

class AddBookStep2CopyImagesUpdated extends AddBookStep2Event {
  final String copyId;
  final List<String> imagePaths;
  AddBookStep2CopyImagesUpdated(this.copyId, this.imagePaths);
}

class AddBookStep2CuratorialNotesUpdated extends AddBookStep2Event {
  final String notes;
  AddBookStep2CuratorialNotesUpdated(this.notes);
}

class AddBookStep2CategoryUpdated extends AddBookStep2Event {
  final String category;
  AddBookStep2CategoryUpdated(this.category);
}

class AddBookStep2AddressUpdated extends AddBookStep2Event {
  final String address;
  AddBookStep2AddressUpdated(this.address);
}

class AddBookStep2FinalizePressed extends AddBookStep2Event {}

// --- States ---
enum AddBookStep2Status { initial, loading, submitting, success, error }

class AddBookStep2State {
  final ListingDraft draft;
  final AddBookStep2Status status;
  final String? errorMessage;
  final String? expandedCopyId;

  const AddBookStep2State({
    this.draft = const ListingDraft(),
    this.status = AddBookStep2Status.initial,
    this.errorMessage,
    this.expandedCopyId,
  });

  AddBookStep2State copyWith({
    ListingDraft? draft,
    AddBookStep2Status? status,
    String? errorMessage,
    String? expandedCopyId,
    bool clearExpandedId = false,
  }) {
    return AddBookStep2State(
      draft: draft ?? this.draft,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      expandedCopyId: clearExpandedId
          ? null
          : (expandedCopyId ?? this.expandedCopyId),
    );
  }
}

// --- Bloc ---
class AddBookStep2Bloc extends Bloc<AddBookStep2Event, AddBookStep2State> {
  final ListingRepository listingRepository;

  AddBookStep2Bloc({required this.listingRepository})
    : super(const AddBookStep2State()) {
    on<AddBookStep2InitialDraftLoaded>(_onInitialDraftLoaded);
    on<AddBookStep2AddCopyPressed>(_onAddCopyPressed);
    on<AddBookStep2RemoveCopyPressed>(_onRemoveCopyPressed);
    on<AddBookStep2CopyUpdated>(_onCopyUpdated);
    on<AddBookStep2CopyExpansionToggled>(_onCopyExpansionToggled);
    on<AddBookStep2CopyImagesUpdated>(_onCopyImagesUpdated);
    on<AddBookStep2CuratorialNotesUpdated>(_onCuratorialNotesUpdated);
    on<AddBookStep2CategoryUpdated>(_onCategoryUpdated);
    on<AddBookStep2AddressUpdated>(_onAddressUpdated);
    on<AddBookStep2FinalizePressed>(_onFinalizePressed);
  }

  void _onInitialDraftLoaded(
    AddBookStep2InitialDraftLoaded event,
    Emitter<AddBookStep2State> emit,
  ) {
    ListingDraft draft = event.draft;
    String? expandedId;

    if (draft.copies.isEmpty) {
      // Add a primary placeholder copy if none exist
      final copyId = DateTime.now().millisecondsSinceEpoch.toString();
      final placeholderCopy = BookCopy(
        id: copyId,
        condition: BookCondition.good,
        listingType: ListingType.sell,
      );
      draft = draft.copyWith(copies: [placeholderCopy]);
      expandedId = copyId;
    } else {
      expandedId = draft.copies.first.id;
    }

    emit(state.copyWith(draft: draft, expandedCopyId: expandedId));
  }

  void _onAddCopyPressed(
    AddBookStep2AddCopyPressed event,
    Emitter<AddBookStep2State> emit,
  ) {
    final copyId = DateTime.now().millisecondsSinceEpoch.toString();
    final newCopy = BookCopy(
      id: copyId,
      condition: BookCondition.good,
      listingType: ListingType.sell,
    );
    final updatedCopies = List<BookCopy>.from(state.draft.copies)..add(newCopy);
    emit(
      state.copyWith(
        draft: state.draft.copyWith(copies: updatedCopies),
        expandedCopyId: copyId, // Auto-expand new copy
      ),
    );
  }

  void _onRemoveCopyPressed(
    AddBookStep2RemoveCopyPressed event,
    Emitter<AddBookStep2State> emit,
  ) {
    final updatedCopies = state.draft.copies
        .where((copy) => copy.id != event.copyId)
        .toList();

    String? nextExpandedId = state.expandedCopyId;
    if (state.expandedCopyId == event.copyId) {
      nextExpandedId = updatedCopies.isNotEmpty ? updatedCopies.last.id : null;
    }

    emit(
      state.copyWith(
        draft: state.draft.copyWith(copies: updatedCopies),
        expandedCopyId: nextExpandedId,
        clearExpandedId: nextExpandedId == null,
      ),
    );
  }

  void _onCopyUpdated(
    AddBookStep2CopyUpdated event,
    Emitter<AddBookStep2State> emit,
  ) {
    // Business Logic: Nullify price if not listing for Sale
    BookCopy updatedCopy = event.copy;
    if (updatedCopy.listingType != ListingType.sell) {
      updatedCopy = updatedCopy.copyWith(price: null);
    }

    final updatedCopies = state.draft.copies.map((copy) {
      return copy.id == updatedCopy.id ? updatedCopy : copy;
    }).toList();

    emit(state.copyWith(draft: state.draft.copyWith(copies: updatedCopies)));
  }

  void _onCopyExpansionToggled(
    AddBookStep2CopyExpansionToggled event,
    Emitter<AddBookStep2State> emit,
  ) {
    if (state.expandedCopyId == event.copyId) {
      emit(state.copyWith(clearExpandedId: true));
    } else {
      emit(state.copyWith(expandedCopyId: event.copyId));
    }
  }

  void _onCopyImagesUpdated(
    AddBookStep2CopyImagesUpdated event,
    Emitter<AddBookStep2State> emit,
  ) {
    final updatedCopies = state.draft.copies.map((copy) {
      if (copy.id == event.copyId) {
        return copy.copyWith(imagePaths: event.imagePaths);
      }
      return copy;
    }).toList();

    emit(state.copyWith(draft: state.draft.copyWith(copies: updatedCopies)));
  }

  void _onCuratorialNotesUpdated(
    AddBookStep2CuratorialNotesUpdated event,
    Emitter<AddBookStep2State> emit,
  ) {
    emit(
      state.copyWith(draft: state.draft.copyWith(curatorialNotes: event.notes)),
    );
  }

  void _onCategoryUpdated(
    AddBookStep2CategoryUpdated event,
    Emitter<AddBookStep2State> emit,
  ) {
    emit(state.copyWith(draft: state.draft.copyWith(category: event.category)));
  }

  void _onAddressUpdated(
    AddBookStep2AddressUpdated event,
    Emitter<AddBookStep2State> emit,
  ) {
    emit(state.copyWith(draft: state.draft.copyWith(address: event.address)));
  }

  Future<void> _onFinalizePressed(
    AddBookStep2FinalizePressed event,
    Emitter<AddBookStep2State> emit,
  ) async {
    if (state.draft.copies.isEmpty) {
      emit(
        state.copyWith(
          status: AddBookStep2Status.error,
          errorMessage: 'At least one copy is required',
        ),
      );
      return;
    }

    emit(state.copyWith(status: AddBookStep2Status.submitting));

    final result = await listingRepository.finalizeListing(state.draft);

    if (result.isSuccess) {
      emit(state.copyWith(status: AddBookStep2Status.success));
    } else {
      emit(
        state.copyWith(
          status: AddBookStep2Status.error,
          errorMessage: result.failure?.message ?? 'Failed to finalize listing',
        ),
      );
    }
  }
}
