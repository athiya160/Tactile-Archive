import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/address.dart';
import '../../domain/usecases/get_saved_addresses.dart';
import '../../domain/usecases/add_new_address.dart';
import '../../domain/usecases/edit_address.dart';
import '../../domain/usecases/select_address.dart';
import '../../domain/usecases/delete_address.dart';
import '../../../cart/domain/usecases/set_cart_delivery_address.dart';
import 'address_event.dart';
import 'address_state.dart';

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  final GetSavedAddresses getSavedAddresses;
  final AddNewAddress addNewAddress;
  final EditAddress editAddress;
  final SelectAddress selectAddress;
  final DeleteAddress deleteAddress;
  final SetCartDeliveryAddress setCartDeliveryAddress;

  AddressBloc({
    required this.getSavedAddresses,
    required this.addNewAddress,
    required this.editAddress,
    required this.selectAddress,
    required this.deleteAddress,
    required this.setCartDeliveryAddress,
  }) : super(const AddressState()) {
    on<AddressStarted>(_onStarted);
    on<AddressSelected>(_onSelected);
    on<AddAddressPressed>(_onAddAddress);
    on<EditAddressPressed>(_onEditAddress);
    on<ConfirmAddressPressed>(_onConfirm);
    on<AddressDeletePressed>(_onDelete);
  }

  Future<void> _onStarted(
    AddressStarted event,
    Emitter<AddressState> emit,
  ) async {
    emit(state.copyWith(status: AddressStatus.loading));
    try {
      final result = await getSavedAddresses();
      result.fold(
        (failure) => emit(
          state.copyWith(
            status: AddressStatus.failure,
            errorMessage: failure.message,
          ),
        ),
        (addresses) {
          // Pre-select the default address if none is selected yet.
          final defaultId = addresses.isNotEmpty
              ? (addresses
                    .cast<Address>()
                    .firstWhere(
                      (a) => a.isDefault,
                      orElse: () => addresses.first,
                    )
                    .id)
              : null;
          emit(
            state.copyWith(
              status: AddressStatus.success,
              addresses: addresses,
              selectedAddressId: state.selectedAddressId ?? defaultId,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AddressStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSelected(
    AddressSelected event,
    Emitter<AddressState> emit,
  ) async {
    // Optimistic update — reflect selection immediately in the UI.
    emit(state.copyWith(selectedAddressId: event.id));
    try {
      // Persist the selection (fire-and-forget; failure is non-critical).
      await selectAddress(event.id);
    } catch (e) {
      // Non-critical but good to handle/log.
    }
  }

  Future<void> _onAddAddress(
    AddAddressPressed event,
    Emitter<AddressState> emit,
  ) async {
    try {
      final addResult = await addNewAddress(event.address);
      if (addResult.isFailure) {
        emit(
          state.copyWith(
            status: AddressStatus.failure,
            errorMessage: addResult.failure?.message,
          ),
        );
        return;
      }
      // Refresh the address list so the new address appears immediately.
      final listResult = await getSavedAddresses();
      listResult.fold(
        (failure) => emit(
          state.copyWith(
            status: AddressStatus.failure,
            errorMessage: failure.message,
          ),
        ),
        (addresses) {
          // Find the newly added address in the list to select it automatically
          final newAddressId = addresses.isNotEmpty
              ? (addresses
                    .cast<Address>()
                    .firstWhere(
                      (a) =>
                          a.recipientName == event.address.recipientName &&
                          a.street == event.address.street &&
                          a.zipCode == event.address.zipCode,
                      orElse: () => addresses.last,
                    )
                    .id)
              : null;
          emit(
            state.copyWith(
              status: AddressStatus.success,
              addresses: addresses,
              selectedAddressId: newAddressId,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AddressStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Marks the address choice as confirmed.
  /// The selected address is already persisted via [AddressSelected].
  /// When checkout occurs, [CartBloc] should read the confirmed address from
  /// state or from the address repository.
  Future<void> _onConfirm(
    ConfirmAddressPressed event,
    Emitter<AddressState> emit,
  ) async {
    try {
      if (state.selectedAddressId != null) {
        final selectedAddress = state.addresses.cast<Address>().firstWhere(
          (a) => a.id == state.selectedAddressId,
          orElse: () => state.addresses.first,
        );
        final addressStr =
            '${selectedAddress.street}\n${selectedAddress.city}, ${selectedAddress.state} ${selectedAddress.zipCode}';

        await setCartDeliveryAddress(
          SetCartDeliveryAddressParams(
            address: addressStr,
            recipient: selectedAddress.recipientName,
          ),
        );
      }
      emit(state.copyWith(status: AddressStatus.confirmed));
    } catch (e) {
      emit(
        state.copyWith(
          status: AddressStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDelete(
    AddressDeletePressed event,
    Emitter<AddressState> emit,
  ) async {
    try {
      final result = await deleteAddress(event.id);
      if (result.isFailure) {
        emit(
          state.copyWith(
            status: AddressStatus.failure,
            errorMessage: result.failure?.message,
          ),
        );
        return;
      }

      // Refresh the address list
      add(AddressStarted());
    } catch (e) {
      emit(
        state.copyWith(
          status: AddressStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onEditAddress(
    EditAddressPressed event,
    Emitter<AddressState> emit,
  ) async {
    try {
      final editResult = await editAddress(event.address);
      if (editResult.isFailure) {
        emit(
          state.copyWith(
            status: AddressStatus.failure,
            errorMessage: editResult.failure?.message,
          ),
        );
        return;
      }
      // Refresh the address list so the changes appear immediately.
      final listResult = await getSavedAddresses();
      listResult.fold(
        (failure) => emit(
          state.copyWith(
            status: AddressStatus.failure,
            errorMessage: failure.message,
          ),
        ),
        (addresses) => emit(
          state.copyWith(status: AddressStatus.success, addresses: addresses),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AddressStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
