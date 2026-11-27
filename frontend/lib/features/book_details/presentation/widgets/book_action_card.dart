import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../home/domain/entities/book.dart';
import '../../../../core/services/borrow_service.dart';
import 'package:libri_flow/core/design_system/tokens/ds_colors.dart';

class BookActionCard extends StatefulWidget {
  final Book book;
  final void Function(int days)? onBorrow;
  final void Function(int days)? onRent;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  const BookActionCard({
    super.key,
    required this.book,
    this.onBorrow,
    this.onRent,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  @override
  State<BookActionCard> createState() => _BookActionCardState();
}

class _BookActionCardState extends State<BookActionCard> {
  late String _selectedTab;
  int _selectedDurationDays = 14;
  final TextEditingController _pincodeController = TextEditingController();
  String? _pincodeStatusMessage;

  @override
  void initState() {
    super.initState();
    if (widget.book.canRent) {
      _selectedTab = 'Rent';
    } else if (widget.book.canBuy) {
      _selectedTab = 'Buy';
    } else if (widget.book.canBorrow) {
      _selectedTab = 'Borrow';
    } else {
      _selectedTab = 'Buy';
    }

    BorrowService.init().then((_) {
      if (mounted) setState(() {});
    });
    BorrowService.changeNotifier.addListener(_onBorrowChanged);
  }

  void _onBorrowChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    BorrowService.changeNotifier.removeListener(_onBorrowChanged);
    _pincodeController.dispose();
    super.dispose();
  }

  double get _calculatedRentalFee {
    final opts = widget.book.rentalOptions;
    if (opts != null) {
      if (_selectedDurationDays <= 7 && opts['fee_7d'] != null) {
        return (opts['fee_7d'] as num).toDouble();
      }
      if (_selectedDurationDays <= 14 && opts['fee_14d'] != null) {
        return (opts['fee_14d'] as num).toDouble();
      }
      if (_selectedDurationDays <= 30 && opts['fee_30d'] != null) {
        return (opts['fee_30d'] as num).toDouble();
      }
      if (opts['daily_rate'] != null) {
        return double.parse((_selectedDurationDays * (opts['daily_rate'] as num).toDouble()).toStringAsFixed(2));
      }
    }
    final rate = widget.book.price > 0 ? (widget.book.price * 0.015) : 3.0;
    return double.parse((_selectedDurationDays * rate).toStringAsFixed(2));
  }

  double get _calculatedDeposit {
    final opts = widget.book.rentalOptions;
    if (opts != null && opts['deposit'] != null) {
      return (opts['deposit'] as num).toDouble();
    }
    return widget.book.price > 0 ? (widget.book.price * 0.50) : 50.0;
  }

  void _checkPincode() {
    final pincode = _pincodeController.text.trim();
    if (pincode.length >= 5 && pincode.length <= 6 && int.tryParse(pincode) != null) {
      final pincodeNum = int.parse(pincode);
      final daysToAdd = 2 + (pincodeNum % 3);
      final deliveryDate = DateTime.now().add(Duration(days: daysToAdd));
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final formattedDate = '${dayNames[deliveryDate.weekday - 1]}, ${monthNames[deliveryDate.month - 1]} ${deliveryDate.day}';

      setState(() {
        _pincodeStatusMessage = '🚚 Eligible for free delivery by $formattedDate!';
      });
    } else {
      setState(() {
        _pincodeStatusMessage = 'Please enter a valid 5 or 6-digit pincode';
      });
    }
  }

  Future<void> _launchExternal(String store) async {
    final title = Uri.encodeComponent('${widget.book.title} ${widget.book.author}');
    String url = 'https://www.amazon.in/s?k=$title';
    if (store == 'flipkart') {
      url = 'https://www.flipkart.com/search?q=$title';
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<String> get _availableTabs {
    final tabs = <String>[];
    if (widget.book.canRent) tabs.add('Rent');
    if (widget.book.canBorrow) tabs.add('Borrow');
    if (widget.book.canBuy) tabs.add('Buy');
    if (tabs.isEmpty) tabs.add('Buy');
    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    final returnDate = DateTime.now().add(Duration(days: _selectedDurationDays));
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final formattedReturnDate = '${returnDate.day} ${monthNames[returnDate.month - 1]} ${returnDate.year}';
    final tabs = _availableTabs;
    if (!tabs.contains(_selectedTab)) {
      _selectedTab = tabs.first;
    }

    final isAvailable = widget.book.isAvailable;
    final providerName = widget.book.providerName ?? 'Community Provider';

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DSColors.softBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Out of stock / unavailable banner
            if (!isAvailable) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.book.stock == 0
                            ? 'Currently Out of Stock'
                            : 'Listing Pending Approval / Paused',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 1. BUY / RENT / BORROW TAB SELECTOR
            Row(
              children: [
                const Icon(Icons.sell_outlined, size: 16, color: Color(0xFFC85A32)),
                const SizedBox(width: 6),
                Text(
                  'Transaction Options',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: DSColors.charcoal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: tabs.map((tab) {
                final isSelected = _selectedTab == tab;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () => setState(() => _selectedTab = tab),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? DSColors.deepForestGreen : const Color(0xFFF7FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? DSColors.deepForestGreen : DSColors.softBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            tab,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : DSColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 2. DURATION SELECTOR (FOR RENT & BORROW)
            if (_selectedTab != 'Buy') ...[
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Text(
                    _selectedTab == 'Borrow' ? 'Borrow Duration' : 'Rental Duration',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: DSColors.charcoal,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Text(
                      'Due: $formattedReturnDate',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: DSColors.secondaryGreen),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Duration Presets & Stepper
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildDurationChip(7, '7d'),
                  _buildDurationChip(14, '14d'),
                  _buildDurationChip(20, '20d'),
                  _buildDurationChip(30, '30d'),
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: DSColors.softBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            if (_selectedDurationDays > 3) {
                              setState(() => _selectedDurationDays--);
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(Icons.remove, size: 14, color: DSColors.textMuted),
                          ),
                        ),
                        Text(
                          '$_selectedDurationDays d',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: DSColors.charcoal),
                        ),
                        InkWell(
                          onTap: () {
                            if (_selectedDurationDays < 60) {
                              setState(() => _selectedDurationDays++);
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(Icons.add, size: 14, color: DSColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // 3. DYNAMIC PRICE & BREAKDOWN
            Text(
              _selectedTab == 'Buy'
                  ? 'Purchase Price'
                  : (_selectedTab == 'Borrow' ? 'Free Community Lending' : 'Rental Rates & Deposit'),
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF718096)),
            ),
            const SizedBox(height: 4),

            if (_selectedTab == 'Buy') ...[
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    '₹${widget.book.price.toStringAsFixed(0)}',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: DSColors.deepForestGreen,
                    ),
                  ),
                  if (widget.book.hasDiscount && widget.book.originalPrice != null) ...[
                    Text(
                      '₹${widget.book.originalPrice!.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        decoration: TextDecoration.lineThrough,
                        color: const Color(0xFFA0AEC0),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${widget.book.discountPercentage!.toInt()}% OFF',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ] else if (_selectedTab == 'Rent') ...[
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    '₹${_calculatedRentalFee.toInt()}',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: DSColors.deepForestGreen,
                    ),
                  ),
                  Text(
                    'for $_selectedDurationDays days',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF718096)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Refundable Security Deposit: ₹${_calculatedDeposit.toInt()}',
                style: GoogleFonts.inter(fontSize: 11, color: DSColors.secondaryGreen, fontWeight: FontWeight.w500),
              ),
            ] else ...[
              Text(
                '₹0 (Free Borrowing)',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: DSColors.secondaryGreen,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Peer-to-peer trust-based lending for $_selectedDurationDays days',
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096)),
              ),
            ],
            const SizedBox(height: 16),

            // 4. PINCODE DELIVERY CHECKINPUT
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      onSubmitted: (_) => _checkPincode(),
                      onChanged: (val) {
                        if (_pincodeStatusMessage != null) {
                          setState(() => _pincodeStatusMessage = null);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter Pincode',
                        hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA0AEC0)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: DSColors.softBorder),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _checkPincode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD69E2E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Check', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
            if (_pincodeStatusMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                _pincodeStatusMessage!,
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF2F855A)),
              ),
            ],
            const SizedBox(height: 16),

            // 5. VALUE PROPOSITIONS LIST
            _buildValueProp(Icons.local_shipping_outlined, 'Free delivery on orders over ₹499'),
            const SizedBox(height: 8),
            _buildValueProp(Icons.history, 'Flexible return window & renewal'),
            const SizedBox(height: 8),
            _buildValueProp(Icons.security, '100% verified peer community'),
            const SizedBox(height: 20),

            // 6. CONTEXTUAL ACTION BUTTONS
            if (_selectedTab == 'Borrow') ...[
              Builder(
                builder: (context) {
                  final req = BorrowService.getRequestForBook(widget.book.id, widget.book.title);
                  final hasActive = req != null && req.stage != BorrowStage.compose;

                  if (hasActive) {
                    final isAccepted = req.stage == BorrowStage.accepted;
                    final isConfirmed = req.stage == BorrowStage.confirmed;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isAccepted ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isAccepted ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isConfirmed
                                    ? Icons.check_circle
                                    : (isAccepted ? Icons.celebration : Icons.hourglass_top),
                                size: 18,
                                color: isAccepted || isConfirmed
                                    ? DSColors.secondaryGreen
                                    : const Color(0xFFD97706),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isConfirmed
                                      ? 'Handover Scheduled!'
                                      : (isAccepted
                                          ? 'Request Accepted by $providerName!'
                                          : 'Borrow Request Sent (Pending)'),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isAccepted || isConfirmed
                                        ? DSColors.secondaryGreen
                                        : const Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isConfirmed
                                ? 'Delivery address confirmed for order.'
                                : (isAccepted
                                    ? '$providerName approved! Enter your delivery address to receive the book.'
                                    : 'Your message has been delivered to $providerName. Address bar unlocks on approval.'),
                            style: GoogleFonts.inter(fontSize: 10, color: DSColors.textMuted),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton.icon(
                              onPressed: isAvailable ? () => widget.onBorrow?.call(_selectedDurationDays) : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isAccepted || isConfirmed
                                    ? DSColors.secondaryGreen
                                    : DSColors.deepForestGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              icon: Icon(
                                isAccepted ? Icons.location_on : Icons.visibility_outlined,
                                size: 15,
                              ),
                              label: Text(
                                isAccepted
                                    ? 'Enter Delivery Address'
                                    : (isConfirmed ? 'View Handover Status' : 'View Request & Status'),
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: isAvailable ? () => widget.onBorrow?.call(_selectedDurationDays) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAvailable ? DSColors.deepForestGreen : const Color(0xFFCBD5E1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.handshake_outlined, size: 18),
                      label: Text(
                        isAvailable
                            ? 'Request to Borrow (Free • $_selectedDurationDays d)'
                            : 'Currently Unavailable',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              if (widget.book.canRent)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: isAvailable ? () => widget.onRent?.call(_selectedDurationDays) : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DSColors.deepForestGreen,
                      side: const BorderSide(color: DSColors.deepForestGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.timer_outlined, size: 16),
                    label: Text(
                      'Rent Instead',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
            ] else if (_selectedTab == 'Rent') ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: isAvailable ? () => widget.onRent?.call(_selectedDurationDays) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAvailable ? DSColors.deepForestGreen : const Color(0xFFCBD5E1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.timer_outlined, size: 18),
                  label: Text(
                    isAvailable
                        ? 'Rent for $_selectedDurationDays Days • ₹${_calculatedRentalFee.toInt()}'
                        : 'Currently Unavailable',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (widget.book.canBorrow)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: isAvailable ? () => widget.onBorrow?.call(_selectedDurationDays) : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DSColors.deepForestGreen,
                      side: const BorderSide(color: DSColors.deepForestGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.handshake_outlined, size: 16),
                    label: Text(
                      'Request to Borrow (Free)',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: isAvailable ? widget.onBuyNow : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAvailable ? DSColors.deepForestGreen : const Color(0xFFCBD5E1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: Text(
                    isAvailable ? 'Buy & Own Now' : 'Currently Unavailable',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: isAvailable ? widget.onAddToCart : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DSColors.deepForestGreen,
                    side: const BorderSide(color: DSColors.deepForestGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                  label: Text(
                    'Add to Cart',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // 6. EXTERNAL PLATFORM LINKS
            Text(
              '🏷️ Compare on other stores',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF718096)),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _launchExternal('amazon'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DSColors.charcoal,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Text('a', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    label: const Text('Amazon'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _launchExternal('flipkart'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DSColors.charcoal,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Text('🛍️', style: TextStyle(fontSize: 14)),
                    label: const Text('Flipkart'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationChip(int days, String label) {
    final isSelected = _selectedDurationDays == days;
    return InkWell(
      onTap: () => setState(() => _selectedDurationDays = days),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? DSColors.deepForestGreen : const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? DSColors.deepForestGreen : DSColors.softBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : DSColors.charcoal,
          ),
        ),
      ),
    );
  }

  Widget _buildValueProp(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF718096)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 12, color: DSColors.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
