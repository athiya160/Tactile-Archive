import 'dart:async';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_item.dart';
import '../../../../core/services/api_service.dart';

class CartDataSource {
  final _cartController = StreamController<Cart>.broadcast();
  Cart _currentCart = Cart(
    items: [
      CartItem(
        id: '1',
        bookId: 'book_1',
        title: 'Meditations',
        author: 'Marcus Aurelius',
        coverUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCKY8DjC4ShVGB1AItxhSp3JocbFIlvWCcLBZ_Hs3ii6FkDNN6Yo7Mmk_d6AMFLvJy9PRHbXIytFqsfT7Qsw_jCnW_WnzPAIpHvgzYtkH2GLgqQw7-gP0CK0tTWrbuKDBYcwJGve2PxkwKIqvSGNqjrPWrxqSnnZ3REC94b_esH8z05tK5A90sxeHoTIQMxS5i60-1lcYSsaIsqVqtngvYvaNMZwmVJArC1ZAw2ZVSXWJbXPqhjOPbiGQ10vm1gbr4MIELiZiqDjA-f',
        price: 24.00,
        isPurchase: true,
      ),
      CartItem(
        id: '2',
        bookId: 'book_2',
        title: 'The Shadow of the Wind',
        author: 'Carlos Ruiz Zafón',
        coverUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCl6vc62Gs397DDBWXBNgWx45WxbVMYbkrrjbT7143p17V0NhmROLa0lTvw21QYUAqjhoeEZszJCGZN_aK7WS8VvttWZdsuHGNkF6VaZxOdlgxPqWV9yDICcszGX5cv-pgorspNv9VzMqPteu5ku4nqrH2mfcu7AeBqKbQ16mqKwJWfskRYNf5XiAN8GoO8vzbG7xqcITcV1fVrlSpKugHMFXfcdosRq1jDY0tUcosERg0P3h8ayMiX-3HhJBX7fEsKefUXs-JEMrtv',
        price: 4.50,
        isPurchase: false,
        rentalDays: 30,
      ),
      CartItem(
        id: '3',
        bookId: 'book_3',
        title: 'Notes from Underground',
        author: 'Fyodor Dostoevsky',
        coverUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBS0YDS9WFgb-P6feTVzNITXStpR9cGD3xnjh_ASgnv7a-sZ5kfUXNtLPXugnmAsq2OYXBgTceVCogChnjkvyZOzpM_sJBaFtmyD8-FKzHC4A71h3DJO_F9AYm7B3eVHeA2hTxizZ6ex8cd5_O7Cy6I3HGB3iEd81x_9Y6D1kpRtCNxTigpdrtgPBkR_8WpbPDTrdrwGiwt_R3-af5X1EVXb9neOzZX42VaNnlWLixQ7U7THfdLoSKxV2OIGt6pafvKVYInm19YHY-k',
        price: 18.90,
        isPurchase: true,
      ),
    ],
    recipientName: ApiService.userName ?? 'Elena Gilbert',
    deliveryAddress:
        '21B Baker Street, Marylebone\nLondon, NW1 6XE\nUnited Kingdom',
  );

  CartDataSource() {
    _cartController.add(_currentCart);
  }

  Stream<Cart> watchCart() => _cartController.stream;
  Cart get currentCart => _currentCart;

  void updateCart(Cart cart) {
    _currentCart = cart;
    _cartController.add(_currentCart);
  }

  void removeItem(String id) {
    final updatedItems = _currentCart.items
        .where((item) => item.id != id)
        .toList();
    updateCart(_currentCart.copyWith(items: updatedItems));
  }

  void updateItemQuantity(String id, int quantity) {
    final updatedItems = _currentCart.items.map((item) {
      if (item.id == id) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    updateCart(_currentCart.copyWith(items: updatedItems));
  }

  void setAddress(String address, String recipient) {
    updateCart(
      _currentCart.copyWith(deliveryAddress: address, recipientName: recipient),
    );
  }

  void clearGuestCart() {
    updateCart(const Cart(items: []));
  }
}
