import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/orders_bloc.dart';
import '../widgets/order_card.dart';
import '../widgets/order_filter_tabs.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.background,
      appBar: AppBar(
        title: const Text('Order History', style: TextStyle(color: DSColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: DSColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DSColors.textDark),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<OrdersBloc, OrdersState>(
          builder: (context, state) {
            return Column(
          children: [
            const SizedBox(height: 8),
            // Filter Tabs
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DSSpacing.md,
                DSSpacing.xl,
                DSSpacing.md,
                DSSpacing.xl,
              ),

              child: OrderFilterTabs(
                selectedFilter: state.selectedFilter,
                onFilterChanged: (filter) {
                  context.read<OrdersBloc>().add(OrdersFilterChanged(filter));
                },
              ),
            ),
            // List and Stats
            // List and Stats
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: DSColors.primary),
                ),
              )
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DSSpacing.md,
                    0,
                    DSSpacing.md,
                    DSSpacing.xl,
                  ),
                  child: state.orders.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 64),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: DSColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 48,
                                    color: DSColors.textLight.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    state.selectedFilter == 'Pending'
                                        ? 'No pending orders'
                                        : 'No order history',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: DSColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'You have not placed any orders yet.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: DSColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                            onRefresh: () async {
                              context.read<OrdersBloc>().add(OrdersStarted());
                            },
                            color: DSColors.primary,
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: state.orders.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: DSSpacing.md),
                                  child: OrderCard(order: state.orders[index]),
                                );
                              },
                            ),
                          ),
                ),
              ),
          ],
        );
      },
    ),
      ),
    );
  }
}
