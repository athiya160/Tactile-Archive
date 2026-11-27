import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import 'buy_now_event.dart';
import 'buy_now_state.dart';

class BuyNowBloc extends Bloc<BuyNowEvent, BuyNowState> {
  final ApiClient apiClient;

  BuyNowBloc({required this.apiClient}) : super(BuyNowInitial()) {
    on<BuyNowCheckoutPressed>(_onCheckoutPressed);
  }

  Future<void> _onCheckoutPressed(
    BuyNowCheckoutPressed event,
    Emitter<BuyNowState> emit,
  ) async {
    emit(BuyNowLoading());
    try {
      if (event.paymentVerified) {
        // Order has already been created on the backend during /payments/verify!
        await Future.delayed(const Duration(milliseconds: 500));
        emit(BuyNowSuccess());
        return;
      }

      if (useMock) {
        await Future.delayed(const Duration(seconds: 1));
      } else {
        if (event.mode == 'purchase') {
          await apiClient.postJson(
            '/orders/buy',
            body: {
              'book_id': int.tryParse(event.bookId ?? '') ?? 0,
              'price': event.price ?? 0.0,
              'payment_method': event.paymentMethod,
              'shipping_address': event.shippingAddress,
            },
          );
        } else if (event.mode == 'rental') {
          await apiClient.postJson(
            '/orders/rent',
            body: {
              'book_id': int.tryParse(event.bookId ?? '') ?? 0,
              'rental_days': event.rentalDays ?? 14,
              'rental_fee': event.rentalFee ?? 0.0,
              'payment_method': event.paymentMethod,
              'shipping_address': event.shippingAddress,
            },
          );
        } else if (event.mode == 'borrow') {
          await apiClient.postJson(
            '/orders/borrow',
            body: {
              'book_id': int.tryParse(event.bookId ?? '') ?? 0,
              'duration_days': event.rentalDays ?? 14,
            },
          );
        } else if (event.mode == 'cart') {
          await apiClient.postJson(
            '/orders/checkout',
            body: {
              'payment_method': event.paymentMethod,
              'shipping_address': event.shippingAddress,
            },
          );
        }
      }
      emit(BuyNowSuccess());
    } catch (e) {
      emit(BuyNowError(e.toString()));
    }
  }
}
