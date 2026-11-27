import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/ivory_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import '../../../../core/services/api_service.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/summary_card.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<CartBloc>().add(CartStarted());

    Widget content;
    // Guard: not logged in
    if (!ApiService.isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: DSColors.primary.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: DSColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Your Cart',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: DSColors.deepForestGreen,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Please login or create an account to continue borrowing and checkout.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: DSColors.textLight,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.push('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DSColors.primary,
                    foregroundColor: DSColors.textInverse,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DSRadius.xl),
                    ),
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/register'),
                child: const Text(
                  'Create Account',
                  style: TextStyle(
                    color: DSColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      content = BlocConsumer<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is CartNavigatingToAddress) {
          context.push('/delivery-address');
        }
        if (state is CartCheckoutSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order placed successfully!')),
          );
        }
      },
      builder: (context, state) {
        if (state is CartLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CartLoaded) {
          final cart = state.cart;

          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: DSColors.textLight.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: DSColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Looks like you haven\'t added any books yet.',
                    style: TextStyle(
                      fontSize: 16,
                      color: DSColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/browse'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DSColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DSRadius.lg),
                      ),
                    ),
                    child: const Text('Browse Books'),
                  ),
                ],
              ),
            );
          }

          return _CartContent(cart: cart);
        }

        if (state is CartError) {
          return Center(child: Text('Error: ${state.message}'));
        }

        return const SizedBox.shrink();
      },
    );
    }

    return IvoryScaffold(
      title: 'Shopping Cart',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ),
      body: content,
    );
  }
}

class _CartContent extends StatelessWidget {
  final dynamic cart; // Using dynamic for brevity or import the entity
  const _CartContent({required this.cart});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 900;

        if (isLargeScreen) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  32.0, // DSSpacing.xl
                  100, // Account for glass header
                  32.0,
                  64.0, // DSSpacing.xl
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cart Items Section
                        Expanded(
                          flex: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(bottom: 24.0),
                                child: Text(
                                  'Your Cart',
                                  style: TextStyle(
                                    fontFamily: 'Playfair Display',
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111111),
                                  ),
                                ),
                              ),
                              ...cart.items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 32.0,
                                  ), // DSSpacing.lg
                                  child: InkWell(
                                    onTap: () =>
                                        context.push('/book/${item.bookId}'),
                                    borderRadius: BorderRadius.circular(
                                      16.0,
                                    ), // DSRadius.lg
                                    hoverColor: const Color(
                                      0xFFF3F4F6,
                                    ), // DSColors.surface
                                    child: CartItemCard(
                                      item: item,
                                      onRemove: () => context
                                          .read<CartBloc>()
                                          .add(CartRemovePressed(item.id)),
                                      onIncreaseQuantity: () =>
                                          context.read<CartBloc>().add(
                                            CartItemQuantityIncreased(item.id),
                                          ),
                                      onDecreaseQuantity: () =>
                                          context.read<CartBloc>().add(
                                            CartItemQuantityDecreased(item.id),
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48.0), // DSSpacing.xxl
                        // Summary Section
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              SummaryCard(
                                subtotal: cart.subtotal,
                                archiveFee: cart.archiveFee,
                                shippingFee: cart.shippingFee,
                                total: cart.total,
                                onCheckout: () => context.push('/checkout'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (cart.items.isNotEmpty) _CartBottomBar(cart: cart),
            ],
          );
        }

        // Mobile Layout
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Column(
                  children: [
                    ...cart.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: DSSpacing.md),
                        child: InkWell(
                          onTap: () => context.push('/book/${item.bookId}'),
                          borderRadius: BorderRadius.circular(DSRadius.lg),
                          hoverColor: DSColors.surface,
                          child: CartItemCard(
                            item: item,
                            onRemove: () => context.read<CartBloc>().add(
                              CartRemovePressed(item.id),
                            ),
                            onIncreaseQuantity: () => context
                                .read<CartBloc>()
                                .add(CartItemQuantityIncreased(item.id)),
                            onDecreaseQuantity: () => context
                                .read<CartBloc>()
                                .add(CartItemQuantityDecreased(item.id)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: DSSpacing.md),
                    SummaryCard(
                      subtotal: cart.subtotal,
                      archiveFee: cart.archiveFee,
                      shippingFee: cart.shippingFee,
                      total: cart.total,
                      onCheckout: () => context.push('/checkout'),
                    ),
                  ],
                ),
              ),
            ),
            if (cart.items.isNotEmpty) _CartBottomBar(cart: cart),
          ],
        );
      },
    );
  }
}

class _CartBottomBar extends StatelessWidget {
  final dynamic cart;

  const _CartBottomBar({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0x4DC3C8C1))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Payment',
                  style: TextStyle(fontSize: 14, color: DSColors.textLight),
                ),
                Text(
                  '₹${cart.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: DSColors.textDark,
                  ),
                ),
              ],
            ),
            SizedBox(
              width: 180,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  context.push('/checkout');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DSColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DSRadius.lg),
                  ),
                ),
                child: Text(
                  'Proceed to Checkout (${cart.items.fold(0, (sum, i) => sum + i.quantity)})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
