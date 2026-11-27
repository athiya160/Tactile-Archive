import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/services/api_service.dart';
import '../../domain/entities/order.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class OrderCard extends StatefulWidget {
  final Order order;

  const OrderCard({super.key, required this.order});

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _isTrackingExpanded = false;

  int _getStepIndex(String status) {
    switch (status.toLowerCase()) {
      case 'shipped':
        return 1;
      case 'out_for_delivery':
        return 2;
      case 'delivered':
        return 3;
      case 'pending':
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepIndex = _getStepIndex(widget.order.shippingStatus);
    final stages = ['Ordered', 'Shipped', 'Out for Delivery', 'Delivered'];

    final firstItem = widget.order.items.isNotEmpty ? widget.order.items.first : null;
    final moreCount = widget.order.items.length > 1 ? widget.order.items.length - 1 : 0;

    return Container(
      padding: const EdgeInsets.all(DSSpacing.md),
      decoration: BoxDecoration(
        color: DSColors.border,
        borderRadius: BorderRadius.circular(DSRadius.xl),
        border: Border.all(color: DSColors.borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Cover
              if (firstItem != null)
                Container(
                  width: 80,
                  height: 112,
                  decoration: BoxDecoration(
                    color: DSColors.borderLight,
                    borderRadius: BorderRadius.circular(DSRadius.sm),
                    border: Border.all(color: DSColors.borderLight, width: 1),
                    image: DecorationImage(
                      image: NetworkImage(ApiService.resolveImageUrl(firstItem.book.coverUrl)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(width: 20), // gap-5 per spec
              // Details
              Expanded(
                child: SizedBox(
                  height: 112,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firstItem != null ? firstItem.book.title : 'Order',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: DSColors.primary,
                                    height: 1.2,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (moreCount > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '+ $moreCount more item${moreCount > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    color: DSColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              'Order ID: #${widget.order.id}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontSize: 12, // text-xs per spec
                                    color: DSColors.textLight,
                                  ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ordered On',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        fontSize: 10,
                                        color: DSColors.textLight,
                                      ),
                                ),
                                Text(
                                  DateFormat('d MMM, yyyy').format(widget.order.date),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: DSColors.primary,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DSSpacing.sm),
              // Price and Status
              SizedBox(
                height: 112,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatusBadge(
                      status: widget.order.status,
                      label: widget.order.statusLabel,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontSize: 10,
                                color: DSColors.textLight,
                              ),
                        ),
                        Text(
                          widget.order.totalAmount == 0
                              ? 'Free'
                              : '\$${widget.order.totalAmount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: DSColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Shipping Tracking Toggle
          const SizedBox(height: DSSpacing.md),
          const Divider(height: 1, color: DSColors.borderLight),
          const SizedBox(height: DSSpacing.sm),

          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(
                widget.order.shippingStatus == 'delivered'
                    ? 'Delivered'
                    : 'Shipment Status: ${stages[stepIndex]}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF061B0E),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isTrackingExpanded = !_isTrackingExpanded;
                  });
                },
                icon: Icon(
                  _isTrackingExpanded
                      ? Icons.expand_less_rounded
                      : Icons.local_shipping_outlined,
                  size: 16,
                  color: const Color(0xFF061B0E),
                ),
                label: Text(
                  _isTrackingExpanded ? 'HIDE TRACKING' : 'TRACK PACKAGE',
                  style: IvoryTheme.smallCapsLabel.copyWith(
                    color: const Color(0xFF061B0E),
                  ),
                ),
              ),
            ],
          ),

          // Collapsible Timeline Tracker
          if (_isTrackingExpanded) ...[
            const SizedBox(height: DSSpacing.md),
            // Timeline graphics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                final isCompleted = index <= stepIndex;
                final isLast = index == 3;
                return Expanded(
                  child: Row(
                    children: [
                      // Node circle
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? const Color(0xFF061B0E)
                              : const Color(0xFFEEEEEA),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted
                                ? const Color(0xFF061B0E)
                                : const Color(0xFFC3C8C1),
                            width: 2,
                          ),
                        ),
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF586159),
                                  ),
                                ),
                              ),
                      ),
                      // Connector line
                      if (!isLast)
                        Expanded(
                          child: Container(
                            height: 3,
                            color: index < stepIndex
                                ? const Color(0xFF061B0E)
                                : const Color(0xFFEEEEEA),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: DSSpacing.xs),
            // Timeline labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                final isCurrent = index == stepIndex;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Text(
                      stages[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCurrent
                            ? const Color(0xFF061B0E)
                            : const Color(0xFF737973),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }),
            ),

            // Carrier & Tracking ID Information
            if (widget.order.trackingId != null &&
                widget.order.trackingId!.isNotEmpty) ...[
              const SizedBox(height: DSSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(DSSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEA),
                  borderRadius: BorderRadius.circular(DSRadius.xl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CARRIER: ${(widget.order.carrier ?? 'Tactile Delivery').toUpperCase()}',
                          style: IvoryTheme.smallCapsLabel.copyWith(
                            color: const Color(0xFF586159),
                          ),
                        ),
                        if (widget.order.estimatedDelivery != null)
                          Text(
                            'EST: ${widget.order.estimatedDelivery!.split('T')[0]}',
                            style: IvoryTheme.smallCapsLabel.copyWith(
                              color: const Color(0xFFBA1A1A),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TRACKING ID: ${widget.order.trackingId}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: DSColors.deepForestGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          // Rate this Book Button
          // Rate this Book Button
          if (widget.order.shippingStatus == 'delivered' && firstItem != null) ...[
            const SizedBox(height: DSSpacing.md),
            const Divider(height: 1, color: DSColors.borderLight),
            const SizedBox(height: DSSpacing.sm),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.push(
                    '/review',
                    extra: {
                      'book': firstItem.book,
                      'orderId': widget.order.id,
                    },
                  );
                },
                icon: const Icon(Icons.star_border_rounded, size: 16),
                label: Text(
                  'RATE THIS BOOK',
                  style: IvoryTheme.smallCapsLabel.copyWith(
                    color: const Color(0xFF061B0E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF061B0E),
                  side: const BorderSide(color: Color(0xFF061B0E), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DSRadius.xl),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  final String label;

  const _StatusBadge({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: DSColors.borderLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: IvoryTheme.statusLabel.copyWith(color: DSColors.primary),
      ),
    );
  }
}
