import '../../../../core/utils/result.dart';
import '../entities/cart.dart';

abstract class CartRepository {
  Stream<Cart> watchCart();
  Future<Result<Cart>> getCart();
  Future<Result<void>> removeItem(String id);
  Future<Result<void>> updateItemQuantity(String id, int quantity);
  Future<Result<void>> setDeliveryAddress(String address, String recipient);
  Future<Result<void>> checkout();
}
