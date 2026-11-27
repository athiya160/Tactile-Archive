import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_data_source.dart';
import '../../../../core/services/api_service.dart';

class RemoteCartRepository implements CartRepository {
  final ApiClient apiClient;
  final CartDataSource dataSource;

  RemoteCartRepository(this.apiClient, this.dataSource);

  @override
  Stream<Cart> watchCart() => dataSource.watchCart();

  @override
  Future<Result<Cart>> getCart() async {
    if (!ApiService.isLoggedIn) {
      const emptyCart = Cart(items: [], archiveFee: 1.20, shippingFee: 0.0);
      dataSource.updateCart(emptyCart);
      return Result.success(emptyCart);
    }
    try {
      final response = await apiClient.getJson('/cart');
      if (response is Map<String, dynamic>) {
        final items =
            (response['items'] as List<dynamic>?)
                ?.map((item) => _parseCartItem(item as Map<String, dynamic>))
                .toList() ??
            [];
        final cart = Cart(
          items: items,
          deliveryAddress: response['deliveryAddress']?.toString(),
          recipientName: response['recipientName']?.toString(),
          archiveFee: _parseDouble(response['archiveFee']) ?? 1.20,
          shippingFee: _parseDouble(response['shippingFee']) ?? 0.0,
        );
        dataSource.updateCart(cart);
        return Result.success(cart);
      }
      return Result.failure(const ServerFailure('Invalid cart response'));
    } on Failure catch (error) {
      return Result.failure(error);
    } catch (error) {
      return Result.failure(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Result<void>> removeItem(String id) async {
    try {
      await apiClient.deleteJson('/cart/items/$id');
      dataSource.removeItem(id);
      return Result.success(null);
    } on Failure catch (error) {
      return Result.failure(error);
    } catch (error) {
      return Result.failure(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Result<void>> updateItemQuantity(String id, int quantity) async {
    try {
      await apiClient.putJson('/cart/items/$id', body: {'quantity': quantity});
      dataSource.updateItemQuantity(id, quantity);
      return Result.success(null);
    } on Failure catch (error) {
      return Result.failure(error);
    } catch (error) {
      return Result.failure(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Result<void>> setDeliveryAddress(
    String address,
    String recipient,
  ) async {
    try {
      await apiClient.putJson(
        '/cart/delivery',
        body: {'address': address, 'recipient': recipient},
      );
      dataSource.setAddress(address, recipient);
      return Result.success(null);
    } on Failure catch (error) {
      return Result.failure(error);
    } catch (error) {
      return Result.failure(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Result<void>> checkout() async {
    try {
      // API call removed because the Razorpay Verify endpoint handles 
      // the order creation and cart clearing on the backend.
      // We just need to clear the local cache here.
      dataSource.updateCart(const Cart());
      return Result.success(null);
    } catch (error) {
      return Result.failure(ServerFailure(error.toString()));
    }
  }

  CartItem _parseCartItem(Map<String, dynamic> data) {
    return CartItem(
      id: data['id']?.toString() ?? '',
      bookId: data['bookId']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      author: data['author']?.toString() ?? '',
      coverUrl: data['coverUrl']?.toString() ?? '',
      price: _parseDouble(data['price']) ?? 0.0,
      isPurchase: data['isPurchase'] != false,
      rentalDays: data['rentalDays'] is int ? data['rentalDays'] as int : null,
      quantity: data['quantity'] is int ? data['quantity'] as int : 1,
    );
  }

  double? _parseDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }
}
