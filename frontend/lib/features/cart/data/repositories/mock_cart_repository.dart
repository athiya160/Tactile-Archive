import '../../../../core/utils/result.dart';
import '../../domain/entities/cart.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_data_source.dart';

class MockCartRepository implements CartRepository {
  final CartDataSource dataSource;

  MockCartRepository(this.dataSource);

  @override
  Stream<Cart> watchCart() => dataSource.watchCart();

  @override
  Future<Result<Cart>> getCart() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Result.success(dataSource.currentCart);
  }

  @override
  Future<Result<void>> removeItem(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    dataSource.removeItem(id);
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateItemQuantity(String id, int quantity) async {
    await Future.delayed(const Duration(milliseconds: 100));
    dataSource.updateItemQuantity(id, quantity);
    return Result.success(null);
  }

  @override
  Future<Result<void>> setDeliveryAddress(
    String address,
    String recipient,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    dataSource.setAddress(address, recipient);
    return Result.success(null);
  }

  @override
  Future<Result<void>> checkout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    dataSource.updateCart(const Cart(items: []));
    return Result.success(null);
  }
}
