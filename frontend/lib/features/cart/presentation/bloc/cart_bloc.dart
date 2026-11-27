import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/cart.dart';
import '../../domain/usecases/watch_cart.dart';
import '../../domain/usecases/get_cart.dart';
import '../../domain/usecases/remove_cart_item.dart';
import '../../domain/usecases/update_cart_item_quantity.dart';
import '../../domain/usecases/cart_checkout.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final WatchCart watchCart;
  final GetCart getCart;
  final RemoveCartItem removeCartItem;
  final UpdateCartItemQuantity updateCartItemQuantity;
  final CartCheckout cartCheckout;
  StreamSubscription? _cartSubscription;

  CartBloc({
    required this.watchCart,
    required this.getCart,
    required this.removeCartItem,
    required this.updateCartItemQuantity,
    required this.cartCheckout,
  }) : super(CartInitial()) {
    on<CartStarted>(_onStarted);
    on<CartRemovePressed>(_onRemovePressed);
    on<CartItemQuantityIncreased>(_onQuantityIncreased);
    on<CartItemQuantityDecreased>(_onQuantityDecreased);
    on<CartChangeAddressPressed>(_onChangeAddressPressed);
    on<CartCheckoutPressed>(_onCheckoutPressed);
    on<_CartUpdated>(_onUpdated);
  }

  Future<void> _onStarted(CartStarted event, Emitter<CartState> emit) async {
    emit(CartLoading());

    // Subscribe to cart changes
    await _cartSubscription?.cancel();
    _cartSubscription = watchCart(NoParams()).listen((cart) {
      if (!isClosed) {
        add(_CartUpdated(cart));
      }
    });

    final result = await getCart(NoParams());
    result.fold(
      (failure) => emit(CartError(failure.message)),
      (success) => emit(CartLoaded(success)),
    );
  }

  // Internal event to handle stream updates
  void _onUpdated(_CartUpdated event, Emitter<CartState> emit) {
    emit(CartLoaded(event.cart));
  }

  Future<void> _onRemovePressed(
    CartRemovePressed event,
    Emitter<CartState> emit,
  ) async {
    final currentState = state;
    final result = await removeCartItem(event.itemId);
    result.fold(
      (failure) {
        emit(CartError(failure.message));
        // Restore to previous state after showing error
        if (currentState is CartLoaded) {
          emit(currentState);
        }
      },
      (success) {}, // State will be updated by the stream subscription
    );
  }

  Future<void> _onQuantityIncreased(
    CartItemQuantityIncreased event,
    Emitter<CartState> emit,
  ) async {
    final currentState = state;
    if (currentState is CartLoaded) {
      final item = currentState.cart.items.firstWhere(
        (i) => i.id == event.itemId,
      );
      await updateCartItemQuantity(
        UpdateCartItemQuantityParams(
          itemId: event.itemId,
          quantity: item.quantity + 1,
        ),
      );
    }
  }

  Future<void> _onQuantityDecreased(
    CartItemQuantityDecreased event,
    Emitter<CartState> emit,
  ) async {
    final currentState = state;
    if (currentState is CartLoaded) {
      final item = currentState.cart.items.firstWhere(
        (i) => i.id == event.itemId,
      );
      if (item.quantity > 1) {
        await updateCartItemQuantity(
          UpdateCartItemQuantityParams(
            itemId: event.itemId,
            quantity: item.quantity - 1,
          ),
        );
      } else {
        add(CartRemovePressed(event.itemId));
      }
    }
  }

  void _onChangeAddressPressed(
    CartChangeAddressPressed event,
    Emitter<CartState> emit,
  ) {
    final currentState = state;
    emit(CartNavigatingToAddress());
    if (currentState is CartLoaded) {
      emit(CartLoaded(currentState.cart));
    }
  }

  Future<void> _onCheckoutPressed(
    CartCheckoutPressed event,
    Emitter<CartState> emit,
  ) async {
    emit(CartLoading());
    final result = await cartCheckout(NoParams());
    result.fold(
      (failure) => emit(CartError(failure.message)),
      (success) => emit(CartCheckoutSuccess()),
    );
  }

  @override
  Future<void> close() {
    _cartSubscription?.cancel();
    return super.close();
  }
}

// Internal event class
class _CartUpdated extends CartEvent {
  final Cart cart;
  const _CartUpdated(this.cart);
  @override
  List<Object?> get props => [cart];
}
