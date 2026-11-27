import 'package:flutter/material.dart';
import '../../../home/domain/entities/book.dart';

class BookActionPanel extends StatelessWidget {
  final Book book;
  final VoidCallback onBorrow;
  final VoidCallback onRent;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  const BookActionPanel({
    super.key,
    required this.book,
    required this.onBorrow,
    required this.onRent,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rent this book',
            style: TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${book.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 6.0, left: 4.0),
                child: Text(
                  '/ 14 days',
                  style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bullet Points
          _buildBulletPoint(
            Icons.local_shipping_outlined,
            'Free delivery on orders over ₹500',
          ),
          const SizedBox(height: 12),
          _buildBulletPoint(Icons.access_time, '14 days easy returns'),
          const SizedBox(height: 12),
          _buildBulletPoint(Icons.shield_outlined, 'Secure payment'),

          const SizedBox(height: 32),

          // Action Buttons
          _buildActionButton('Borrow', Icons.book_outlined, true, onBorrow),
          const SizedBox(height: 12),
          _buildActionButton('Rent', Icons.access_time, false, onRent),
          const SizedBox(height: 12),
          _buildActionButton(
            'Add to Cart',
            Icons.shopping_cart_outlined,
            false,
            onAddToCart,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Buy Now',
            Icons.shopping_bag_outlined,
            true,
            onBuyNow,
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF757575)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF424242),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    bool isPrimary,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: isPrimary
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D251D),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0D251D),
                side: const BorderSide(color: Color(0xFFE0E0E0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
    );
  }
}
