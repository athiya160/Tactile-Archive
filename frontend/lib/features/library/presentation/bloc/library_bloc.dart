import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/rental_item.dart';
import '../../domain/entities/upload_item.dart';
import '../../domain/usecases/get_active_rentals.dart';
import '../../domain/usecases/get_my_uploads.dart';
import '../../domain/usecases/delete_upload.dart';
import 'library_event.dart';
import 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final GetActiveRentals getActiveRentals;
  final GetMyUploads getMyUploads;
  final DeleteUpload deleteUpload;

  LibraryBloc({
    required this.getActiveRentals,
    required this.getMyUploads,
    required this.deleteUpload,
  }) : super(LibraryInitial()) {
    on<LibraryStarted>(_onStarted);
    on<LibraryTabChanged>(_onTabChanged);
    on<LibraryDeleteUpload>(_onDeleteUpload);
  }

  Future<void> _onStarted(
    LibraryStarted event,
    Emitter<LibraryState> emit,
  ) async {
    emit(LibraryLoading());
    final rentalsResult = await getActiveRentals(NoParams());
    final uploadsResult = await getMyUploads(NoParams());

    final rentals = rentalsResult.isSuccess ? (rentalsResult.data ?? <RentalItem>[]) : <RentalItem>[];
    final uploads = uploadsResult.isSuccess ? (uploadsResult.data ?? <UploadItem>[]) : <UploadItem>[];

    if (!rentalsResult.isSuccess && !uploadsResult.isSuccess) {
      final msg = rentalsResult.failure?.message ?? 'Unable to connect to archive server.';
      emit(LibraryError(msg));
      return;
    }

    emit(
      LibraryLoaded(
        rentals: rentals,
        uploads: uploads,
        activeTabIndex: event.initialTabIndex,
      ),
    );
  }

  void _onTabChanged(LibraryTabChanged event, Emitter<LibraryState> emit) {
    if (state is LibraryLoaded) {
      emit((state as LibraryLoaded).copyWith(activeTabIndex: event.index));
    }
  }

  Future<void> _onDeleteUpload(
    LibraryDeleteUpload event,
    Emitter<LibraryState> emit,
  ) async {
    final result = await deleteUpload(event.uploadId);
    result.fold((failure) => emit(LibraryError(failure.message)), (_) {
      // Refresh the list
      add(LibraryStarted());
    });
  }
}
