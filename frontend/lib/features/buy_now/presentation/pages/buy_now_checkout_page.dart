import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../home/domain/entities/book.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/borrow_service.dart';
import '../../../../core/services/payment_gateway_service.dart';



class BuyNowCheckoutPage extends StatefulWidget {
  final Book? book;
  final String mode; // rental, borrow, purchase
  final int? rentalDays;
  final double? rentalFee;

  const BuyNowCheckoutPage({
    super.key,
    this.book,
    required this.mode,
    this.rentalDays,
    this.rentalFee,
  });

  @override
  State<BuyNowCheckoutPage> createState() => _BuyNowCheckoutPageState();
}

class _BuyNowCheckoutPageState extends State<BuyNowCheckoutPage> {
  // Standard checkout steps (for rental and purchase)
  int _currentStep = 1; // 1: Delivery Mode Selection, 2: Address/Details, 3: Payment
  String _selectedDeliveryMethod = 'delivery'; // delivery, meetup, dropoff
  String _selectedPaymentMethod = 'upi'; // 'upi', 'card', 'netbanking', 'wallet', 'cod'
  bool _isOrderSuccess = false;
  bool _isProcessingPayment = false;
  dynamic _placedOrderId;

  // 1. UPI Payment State
  Timer? _qrCountdownTimer;
  int _qrCountdownSeconds = 599; // 9m 59s
  String _upiSubMethod = 'apps'; // 'apps' (Instant App Grid), 'qr' (Scan QR), 'vpa' (UPI ID)
  String _selectedUpiApp = 'gpay'; // 'gpay', 'phonepe', 'paytm', 'bhim'
  bool _isUpiIdCopied = false;
  bool _isVpaVerified = false;
  String? _vpaVerifiedName;
  final TextEditingController _upiVpaController = TextEditingController();

  // 2. Card Payment State
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  final TextEditingController _cardCvvController = TextEditingController();
  bool _saveCardForFuture = true;

  // 3. Net Banking State
  String _selectedBank = 'HDFC'; // 'HDFC', 'SBI', 'ICICI', 'AXIS', 'KOTAK', 'PNB'
  String? _selectedOtherBank;

  // 4. Wallets State
  String _selectedWallet = 'libri_escrow'; // 'libri_escrow', 'amazon_pay', 'paytm_wallet', 'phonepe_wallet'
  bool _useEscrowBalance = true;

  // Dedicated Borrow lifecycle state
  BorrowStage _borrowStage = BorrowStage.compose;

  late int _selectedDays;
  late TextEditingController _borrowMessageController;

  String _recipientName = 'Arjun Sharma';
  String _recipientPhone = '+91 98765 43210';
  String _streetAddress = 'Flat 402, Green Valley Apartments, 12th Main Road';
  String _cityStateZip = 'Indiranagar, Bangalore, Karnataka - 560038';
  String _addressLabel = 'HOME';
  String _deliverySpeed = 'standard'; // standard, express
  String _meetupLocation = 'Koramangala 4th Block, Bangalore, Karnataka';
  String _meetupDateTime = 'Tomorrow, 25 May 2024 • 4:00 PM - 6:00 PM';

  bool get _isBorrow => widget.mode.toLowerCase() == 'borrow';
  bool get _isRental => widget.mode.toLowerCase() == 'rental' || widget.mode.toLowerCase() == 'rent';
  bool get _isPurchase => widget.mode.toLowerCase() == 'purchase' || widget.mode.toLowerCase() == 'buy';

  double get _rentalFee {
    if (_isBorrow) return 0.0;
    if (_isRental) {
      return double.parse((_selectedDays * 0.155).toStringAsFixed(2));
    }
    return 0.0;
  }

  double get _securityDeposit {
    if (_isBorrow) return 0.0;
    if (_isRental) return 15.00;
    return 0.0;
  }

  double get _deliveryFee {
    if (_selectedDeliveryMethod == 'meetup') return 0.0;
    if (_deliverySpeed == 'express') return 0.60; // Approx ₹49
    return 0.0; // Standard is free
  }

  double get _totalPayable {
    if (_isBorrow) return _deliveryFee;
    if (_isRental) return _rentalFee + _securityDeposit + _deliveryFee;
    if (_isPurchase) {
      final bookPrice = widget.book?.price != null && widget.book!.price > 0 ? widget.book!.price : 18.00;
      return bookPrice + _deliveryFee;
    }
    return _deliveryFee;
  }

  String get _formattedReturnDate {
    final date = DateTime.now().add(Duration(days: _selectedDays));
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  @override
  void initState() {
    super.initState();
    _startQrCountdown();
    _selectedDays = widget.rentalDays ?? 14;
    _borrowMessageController = TextEditingController(
      text: "Hi Rahul! I'm preparing for my exams and would love to borrow your copy of \"${widget.book?.title ?? 'this book'}\" for $_selectedDays days. I promise to take great care of it and return it on time!",
    );
    if (ApiService.userName != null && ApiService.userName!.isNotEmpty) {
      _recipientName = ApiService.userName!;
    }

    // Check if user already sent a borrow request for this book
    if (_isBorrow) {
      final existing = BorrowService.getRequestForBook(widget.book?.id, widget.book?.title);
      if (existing != null && existing.stage != BorrowStage.compose) {
        _borrowStage = existing.stage;
        _selectedDays = existing.durationDays;
        _borrowMessageController.text = existing.message;
        if (existing.deliveryMethod != null) _selectedDeliveryMethod = existing.deliveryMethod!;
        if (existing.deliveryAddress != null) _streetAddress = existing.deliveryAddress!;
      }

      BorrowService.init().then((_) {
        if (mounted) {
          final req = BorrowService.getRequestForBook(widget.book?.id, widget.book?.title);
          if (req != null && req.stage != BorrowStage.compose) {
            setState(() {
              _borrowStage = req.stage;
              _selectedDays = req.durationDays;
              _borrowMessageController.text = req.message;
              if (req.deliveryMethod != null) _selectedDeliveryMethod = req.deliveryMethod!;
              if (req.deliveryAddress != null) _streetAddress = req.deliveryAddress!;
            });
          }
        }
      });
    }
  }


  void _startQrCountdown() {
    _qrCountdownTimer?.cancel();
    _qrCountdownSeconds = 599;
    _qrCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_qrCountdownSeconds > 0) {
        setState(() => _qrCountdownSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _qrCountdownTimer?.cancel();
    _upiVpaController.dispose();
    _borrowMessageController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  String _getModeLabel(String mode) {
    switch (mode.toLowerCase()) {
      case 'rental':
      case 'rent':
        return 'Rental';
      case 'borrow':
        return 'Borrow';
      case 'purchase':
      case 'buy':
        return 'Purchase';
      default:
        return 'Order';
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book ??
        const Book(
          id: '1',
          title: 'Atomic Habits',
          author: 'James Clear',
          coverUrl: 'https://images-na.ssl-images-amazon.com/images/I/81wgcld4wxL.jpg',
          categories: ['Self Help'],
          price: 150.0,
          listingType: ListingType.forRent,
          rating: 4.8,
        );

    // If regular order success or borrow finalized
    if (_isOrderSuccess || (_isBorrow && _borrowStage == BorrowStage.confirmed)) {
      return _buildSuccessScreen(book);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Top Header with stepper
              _buildTopHeader(context),
              const SizedBox(height: 24),

              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 720),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Order Summary Card (Always Visible)
                      _buildOrderSummaryCard(book),
                      const SizedBox(height: 24),

                      // Dedicated Borrow Flow vs Standard Paid Flow
                      if (_isBorrow) ...[
                        if (_borrowStage == BorrowStage.compose)
                          _buildBorrowComposeStep(book)
                        else if (_borrowStage == BorrowStage.pending)
                          _buildBorrowPendingApprovalCard(book)
                        else if (_borrowStage == BorrowStage.accepted)
                          _buildBorrowAcceptedAddressStep(book),
                      ] else ...[
                        // Standard Paid Checkout (Rental / Purchase)
                        if (_currentStep == 1) _buildStep1DeliveryModeSelection(),
                        if (_currentStep == 2) _buildStep2Content(book),
                        if (_currentStep == 3) _buildStep3PaymentSelection(book),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }

  // 1. TOP HEADER WITH STEPPER
  Widget _buildTopHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  if (_isBorrow) {
                    if (_borrowStage == BorrowStage.accepted) {
                      setState(() => _borrowStage = BorrowStage.pending);
                    } else if (_borrowStage == BorrowStage.pending) {
                      setState(() => _borrowStage = BorrowStage.compose);
                    } else {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/browse');
                      }
                    }
                  } else {
                    if (_currentStep > 1) {
                      setState(() => _currentStep--);
                    } else {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/browse');
                      }
                    }
                  }
                },
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back, size: 16, color: Color(0xFF2D3748)),
                    const SizedBox(width: 6),
                    Text(
                      'Back to Book',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_isBorrow) ...[
                // Borrow-specific 3-stage lifecycle
                _buildStepCircle(
                  1,
                  'Request Note',
                  _borrowStage == BorrowStage.compose,
                  _borrowStage != BorrowStage.compose,
                ),
                _buildStepLine(_borrowStage != BorrowStage.compose),
                _buildStepCircle(
                  2,
                  'Owner Approval',
                  _borrowStage == BorrowStage.pending,
                  _borrowStage == BorrowStage.accepted || _borrowStage == BorrowStage.confirmed,
                ),
                _buildStepLine(_borrowStage == BorrowStage.accepted || _borrowStage == BorrowStage.confirmed),
                _buildStepCircle(
                  3,
                  'Delivery Address',
                  _borrowStage == BorrowStage.accepted,
                  _borrowStage == BorrowStage.confirmed,
                ),
              ] else ...[
                // Regular Store/Rental 3-step checkout
                _buildStepCircle(1, 'Summary', _currentStep == 1, _currentStep > 1),
                _buildStepLine(_currentStep >= 2),
                _buildStepCircle(2, 'Delivery', _currentStep == 2, _currentStep > 2),
                _buildStepLine(_currentStep >= 3),
                _buildStepCircle(3, 'Payment', _currentStep == 3, false),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCircle(int stepNum, String label, bool isCurrent, bool isCompleted) {
    final isHighlighted = isCurrent || isCompleted;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isHighlighted ? const Color(0xFF0D3B2E) : const Color(0xFFE2E8F0),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '$stepNum',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isHighlighted ? Colors.white : const Color(0xFF718096),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            color: isHighlighted ? const Color(0xFF0D3B2E) : const Color(0xFF718096),
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      color: isActive ? const Color(0xFF0D3B2E) : const Color(0xFFE2E8F0),
    );
  }

  // 2. TOP ORDER SUMMARY CARD
  Widget _buildOrderSummaryCard(Book book) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDF2F7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  book.coverUrl.isNotEmpty ? book.coverUrl : 'https://images-na.ssl-images-amazon.com/images/I/81wgcld4wxL.jpg',
                  width: 58,
                  height: 78,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 58,
                    height: 78,
                    color: const Color(0xFFE2E8F0),
                    child: const Icon(Icons.book, size: 24, color: Color(0xFF0D3B2E)),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title & Author & Tag
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0D3B2E),
                      ),
                    ),
                    Text(
                      'by ${book.author}',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF718096)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _isBorrow
                            ? const Color(0xFFE6F4EA)
                            : (_isRental ? const Color(0xFFFEF3C7) : const Color(0xFFEDF2F7)),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _isBorrow
                              ? const Color(0xFFBBF7D0)
                              : (_isRental ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Text(
                        _isBorrow
                            ? '🤝 FREE COMMUNITY BORROW • $_selectedDays DAYS'
                            : (_isRental ? '⏳ RENTAL • $_selectedDays DAYS' : '🛒 PURCHASE & OWN'),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _isBorrow
                              ? const Color(0xFF166534)
                              : (_isRental ? const Color(0xFF92400E) : const Color(0xFF4A5568)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Price Calculation Right Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_isBorrow) ...[
                    Row(
                      children: [
                        Text('Rental Fee', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096))),
                        const SizedBox(width: 16),
                        Text('FREE (\$0.00)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF166534))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Community Trust', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096))),
                        const SizedBox(width: 16),
                        Text('₹0 Deposit', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF166534))),
                      ],
                    ),
                  ] else if (_isRental) ...[
                    Row(
                      children: [
                        Text('Rental ($_selectedDays d)', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096))),
                        const SizedBox(width: 16),
                        Text('\$${_rentalFee.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Deposit (Refundable)', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096))),
                        const SizedBox(width: 16),
                        Text('\$${_securityDeposit.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748))),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Text('Book Price', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096))),
                        const SizedBox(width: 16),
                        Text('\$${_totalPayable.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748))),
                      ],
                    ),
                  ],
                  if (_deliveryFee > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Express Delivery', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096))),
                        const SizedBox(width: 16),
                        Text('\$0.60 (₹49)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E))),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('Total Payable', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E))),
                      const SizedBox(width: 12),
                      Text(
                        _isBorrow && _deliveryFee == 0.0
                            ? 'FREE'
                            : '\$${_totalPayable.toStringAsFixed(2)}',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0D3B2E),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _isBorrow && _deliveryFee == 0.0
                        ? '(₹0.00 • Community Share)'
                        : '(Approx. ₹${(_totalPayable * 82.78).toStringAsFixed(2)})',
                    style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF718096)),
                  ),
                ],
              ),
            ],
          ),

          // Interactive Duration Adjustment Bar
          if (_isRental || _isBorrow) ...[
            const Divider(height: 24, color: Color(0xFFEDF2F7)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF0D3B2E)),
                    const SizedBox(width: 8),
                    Text(
                      _isBorrow ? 'Borrow Period:' : 'Rental Duration:',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748)),
                    ),
                    const SizedBox(width: 10),
                    _buildCheckoutDurationChip(7, '7 Days'),
                    const SizedBox(width: 6),
                    _buildCheckoutDurationChip(14, '14 Days'),
                    const SizedBox(width: 6),
                    _buildCheckoutDurationChip(20, '20 Days'),
                    const SizedBox(width: 6),
                    _buildCheckoutDurationChip(30, '30 Days'),
                    const SizedBox(width: 8),
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFCBD5E0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              if (_selectedDays > 1) {
                                setState(() => _selectedDays--);
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.remove, size: 12, color: Color(0xFF4A5568)),
                            ),
                          ),
                          Text(
                            '$_selectedDays d',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748)),
                          ),
                          InkWell(
                            onTap: () => setState(() => _selectedDays++),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.add, size: 12, color: Color(0xFF4A5568)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Text(
                    'Return by: $_formattedReturnDate',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF166534)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckoutDurationChip(int days, String label) {
    final isSelected = _selectedDays == days;
    return InkWell(
      onTap: () => setState(() => _selectedDays = days),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D3B2E) : const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D3B2E) : const Color(0xFFCBD5E0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF2D3748),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // BORROW SPECIFIC FLOW (STAGE 1 -> STAGE 2 -> STAGE 3)
  // =========================================================================

  // STAGE 1: COMPOSE MESSAGE (Address bar is hidden & locked for privacy)
  Widget _buildBorrowComposeStep(Book book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBorrowMessageCard(),

        // Address Privacy Guarantee Card (Replaces premature address input)
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFF166534), size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔒 Delivery Address Privacy Protected',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF166534),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your delivery address is NOT collected or shared upfront with book owners. '
                      'Once Rahul Sharma reviews your message and accepts your borrow request, the Address Bar will unlock so you can enter your delivery address or arrange a meetup.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF2D3748),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Primary Action: Send Borrow Request
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () async {
              await BorrowService.saveRequest(
                bookId: book.id,
                bookTitle: book.title,
                bookAuthor: book.author,
                bookCoverUrl: book.coverUrl,
                ownerName: 'Rahul Sharma',
                durationDays: _selectedDays,
                message: _borrowMessageController.text.trim(),
                stage: BorrowStage.pending,
              );
              setState(() {
                _borrowStage = BorrowStage.pending;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D3B2E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: Text(
              'Send Borrow Request to Rahul Sharma',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            '🤝 Zero Deposit • No Credit Card Required • Direct Peer Lending',
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096)),
          ),
        ),
      ],
    );
  }

  // STAGE 2: PENDING APPROVAL (Address bar is locked until owner accepts)
  Widget _buildBorrowPendingApprovalCard(Book book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.hourglass_top, color: Color(0xFFD97706), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Borrow Request Sent!',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0D3B2E),
                            ),
                          ),
                          Text(
                            'Request #REQ-2026-8941 • Awaiting Rahul Sharma',
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 8,
                          height: 8,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD97706)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Pending Owner Approval',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFB45309)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28, color: Color(0xFFEDF2F7)),

              // Note Preview Box
              Text(
                'Your Message to Rahul Sharma:',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF4A5568)),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  '"${_borrowMessageController.text}"',
                  style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: const Color(0xFF334155), height: 1.4),
                ),
              ),
              const SizedBox(height: 16),

              // Locked Address Notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, color: Color(0xFFB45309), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Address Bar is Currently Locked',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF92400E)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Rahul has received your request. The moment he taps "Accept", the Address Bar will appear here so you can provide your delivery address.',
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF78350F)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Professional Owner Status Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.mark_email_read_outlined, color: Color(0xFF0D3B2E), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Borrow Request Status: Awaiting Owner Review',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rahul Sharma has been notified via In-App Alert and SMS. Once accepted, your delivery address will be verified and handoff coordinated.',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF4A5568), height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Notification reminder sent to owner.'),
                                  backgroundColor: Color(0xFF0D3B2E),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0D3B2E),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.send_outlined, size: 14),
                            label: Text('Send Reminder', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await BorrowService.updateStage(
                                book.id,
                                book.title,
                                BorrowStage.accepted,
                              );
                              if (!mounted) return;
                              setState(() {
                                _borrowStage = BorrowStage.accepted;
                              });
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Borrow request accepted! Delivery address unlocked.'),
                                  backgroundColor: Color(0xFF166534),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF166534),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.check_circle_outline, size: 14),
                            label: Text('Proceed to Address', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await BorrowService.cancelRequest(book.id, book.title);
                    setState(() => _borrowStage = BorrowStage.compose);
                  },
                  icon: const Icon(Icons.edit_note, size: 14, color: Color(0xFF718096)),
                  label: Text(
                    'Modify Message or Cancel Request',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STAGE 3: REQUEST ACCEPTED -> ADDRESS BAR IS UNLOCKED!
  Widget _buildBorrowAcceptedAddressStep(Book book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Celebration Banner
        Container(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF166534).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.celebration, color: Color(0xFF166534), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Request Accepted by Rahul Sharma!',
                          style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF166534)),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, size: 16, color: Color(0xFF166534)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rahul agreed to lend you "${book.title}". Please enter your delivery address below so we can deliver the book.',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF15803D)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // NOW THE ADDRESS BAR IS PROMINENTLY DISPLAYED
        Text(
          'Where should we deliver this book?',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0D3B2E),
          ),
        ),
        Text(
          'Select your preferred delivery mode or enter your address',
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF718096)),
        ),
        const SizedBox(height: 16),

        // Delivery Method Selector for Borrow
        _buildDeliveryOptionCard(
          id: 'delivery',
          icon: Icons.local_shipping_outlined,
          title: 'Delivery to Your Address',
          badge: 'Recommended',
          subtitle: 'Get the book delivered directly to your doorstep.',
          bullets: ['• Free Standard Delivery', '• Live Handover Tracking'],
        ),
        const SizedBox(height: 12),
        _buildDeliveryOptionCard(
          id: 'meetup',
          icon: Icons.groups_outlined,
          title: 'Peer-to-Peer Meetup',
          subtitle: 'Meet Rahul Sharma in person at a safe public location.',
          bullets: ['• Direct hand-off', '• Flexible timing'],
        ),
        const SizedBox(height: 12),
        _buildDeliveryOptionCard(
          id: 'dropoff',
          icon: Icons.handshake_outlined,
          title: 'Owner Drop-off',
          subtitle: 'Rahul will drop off the book at your building reception or hub.',
          bullets: ['• Contactless pickup'],
        ),
        const SizedBox(height: 20),

        // Active Delivery / Address Bar Card
        if (_selectedDeliveryMethod == 'delivery') ...[
          _buildExpandedDeliveryCard(),
        ] else if (_selectedDeliveryMethod == 'meetup') ...[
          _buildExpandedMeetupCard(book),
        ] else ...[
          _buildExpandedDropoffCard(),
        ],

        const SizedBox(height: 24),

        // Confirm Address & Finalize Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () async {
              await BorrowService.updateStage(
                book.id,
                book.title,
                BorrowStage.confirmed,
                deliveryMethod: _selectedDeliveryMethod,
                deliveryAddress: '$_streetAddress, $_cityStateZip',
                recipientName: _recipientName,
                recipientPhone: _recipientPhone,
              );
              setState(() {
                _borrowStage = BorrowStage.confirmed;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D3B2E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: const Icon(Icons.check_circle, size: 18),
            label: Text(
              'Confirm Address & Finalize Handover',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            '🔒 Your address is securely encrypted and shared solely with Rahul Sharma for this delivery.',
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096)),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // MESSAGE CARD & TEMPLATES
  // =========================================================================

  Widget _buildBorrowMessageCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF166534).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF0D3B2E)),
                  const SizedBox(width: 8),
                  Text(
                    'Message to Book Owner (Rahul Sharma)',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D3B2E),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Community Request',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF166534)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Introduce yourself and let Rahul know why you would like to borrow this book and how you plan to care for it.',
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096)),
          ),
          const SizedBox(height: 12),

          // Quick message template chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildMessageTemplateChip(
                '📚 Exam Prep',
                "Hi Rahul! I'm preparing for exams and would love to borrow this book for $_selectedDays days. I will keep it in pristine condition and return it on time!",
              ),
              _buildMessageTemplateChip(
                '📖 Weekend Read',
                "Hi! I'm an avid reader looking forward to reading this over the next couple of weeks. Will take great care of your copy!",
              ),
              _buildMessageTemplateChip(
                '🎓 Coursework',
                "Hi Rahul! I'm referencing this title for my university coursework. Thank you so much for sharing with the community!",
              ),
              _buildMessageTemplateChip(
                '🤝 Careful Reader',
                "Hi! I treat books with utmost respect and will return it clean and prompt before the due date.",
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Message input
          TextField(
            controller: _borrowMessageController,
            maxLines: 3,
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF2D3748)),
            decoration: InputDecoration(
              hintText: 'Write a polite note to Rahul Sharma...',
              hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA0AEC0)),
              filled: true,
              fillColor: const Color(0xFFF7FAFC),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF0D3B2E), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, size: 12, color: Color(0xFF718096)),
              const SizedBox(width: 6),
              Text(
                'Direct peer communication • Owners typically approve within 12 hours',
                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF718096)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTemplateChip(String label, String template) {
    return InkWell(
      onTap: () {
        setState(() {
          _borrowMessageController.text = template;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF4A5568)),
        ),
      ),
    );
  }

  // =========================================================================
  // STANDARD PAID CHECKOUT FLOW (RENTAL / PURCHASE)
  // =========================================================================

  Widget _buildStep1DeliveryModeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How would you like to receive this book?',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0D3B2E),
          ),
        ),
        Text(
          'Choose the most convenient option for you',
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF718096)),
        ),
        const SizedBox(height: 16),

        _buildDeliveryOptionCard(
          id: 'meetup',
          icon: Icons.groups_outlined,
          title: 'Peer-to-Peer Meetup',
          badge: 'Recommended',
          subtitle: 'Meet the book owner in person at a safe public location.',
          bullets: ['• No delivery fee', '• Connect with community'],
        ),
        const SizedBox(height: 12),

        _buildDeliveryOptionCard(
          id: 'delivery',
          icon: Icons.local_shipping_outlined,
          title: 'Delivery to Your Address',
          subtitle: 'Get the book delivered to your doorstep.',
          bullets: ['• Delivery fee may apply'],
        ),
        const SizedBox(height: 12),

        _buildDeliveryOptionCard(
          id: 'dropoff',
          icon: Icons.handshake_outlined,
          title: 'Owner Drop-off',
          subtitle: 'The owner will drop off the book to your preferred location.',
          bullets: ['• Flexible & convenient'],
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF718096)),
            const SizedBox(width: 6),
            Text(
              'All transactions are safe and secure. We protect your privacy.',
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096)),
            ),
          ],
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => setState(() => _currentStep = 2),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D3B2E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue to Address',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryOptionCard({
    required String id,
    required IconData icon,
    required String title,
    String? badge,
    required String subtitle,
    required List<String> bullets,
  }) {
    final isSelected = _selectedDeliveryMethod == id;

    return InkWell(
      onTap: () => setState(() => _selectedDeliveryMethod = id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F7F4) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D3B2E) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF0D3B2E) : const Color(0xFFCBD5E0),
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF0D3B2E) : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.circle, size: 8, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 28, color: const Color(0xFF0D3B2E)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC6F6D5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF22543D),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF718096))),
                  const SizedBox(height: 4),
                  Row(
                    children: bullets.map((b) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(b, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF4A5568))),
                    )).toList(),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFA0AEC0)),
          ],
        ),
      ),
    );
  }

  // STEP 2: DELIVERY / MEETUP DETAILS
  Widget _buildStep2Content(Book book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedDeliveryMethod == 'delivery') ...[
          _buildExpandedDeliveryCard(),
          const SizedBox(height: 12),
          _buildCollapsedAccordion(
            id: 'meetup',
            icon: Icons.groups_outlined,
            title: 'Peer-to-Peer Meetup',
            subtitle: 'Meet the book owner in person at a safe public location.',
          ),
          const SizedBox(height: 12),
          _buildCollapsedAccordion(
            id: 'dropoff',
            icon: Icons.handshake_outlined,
            title: 'Owner Drop-off',
            subtitle: 'The owner will drop off the book at your designated hub.',
          ),
        ] else if (_selectedDeliveryMethod == 'meetup') ...[
          _buildExpandedMeetupCard(book),
          const SizedBox(height: 12),
          _buildCollapsedAccordion(
            id: 'delivery',
            icon: Icons.local_shipping_outlined,
            title: 'Delivery to Your Address',
            subtitle: 'Get the book delivered directly to your doorstep.',
          ),
          const SizedBox(height: 12),
          _buildCollapsedAccordion(
            id: 'dropoff',
            icon: Icons.handshake_outlined,
            title: 'Owner Drop-off',
            subtitle: 'The owner will drop off the book at your designated hub.',
          ),
        ] else ...[
          _buildExpandedDropoffCard(),
          const SizedBox(height: 12),
          _buildCollapsedAccordion(
            id: 'delivery',
            icon: Icons.local_shipping_outlined,
            title: 'Delivery to Your Address',
            subtitle: 'Get the book delivered directly to your doorstep.',
          ),
          const SizedBox(height: 12),
          _buildCollapsedAccordion(
            id: 'meetup',
            icon: Icons.groups_outlined,
            title: 'Peer-to-Peer Meetup',
            subtitle: 'Meet the book owner in person at a safe public location.',
          ),
        ],

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => setState(() => _currentStep = 3),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D3B2E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Continue to Payment', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'You can review and update these details before confirming your order',
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096)),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedDeliveryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0D3B2E), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D3B2E).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, color: Color(0xFF0D3B2E), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Delivery to Your Address',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D3B2E),
                    ),
                  ),
                ],
              ),
              if (!_isBorrow)
                InkWell(
                  onTap: () => setState(() => _currentStep = 1),
                  child: Text('Change Mode', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E))),
                ),
            ],
          ),
          Text(
            'We will ship this book directly to your registered doorstep address.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF718096)),
          ),
          const SizedBox(height: 16),

          // Address Card Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D3B2E),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _addressLabel,
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _recipientName,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• $_recipientPhone',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF718096)),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => _showChangeAddressDialog(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_outlined, size: 12, color: Color(0xFF0D3B2E)),
                            const SizedBox(width: 4),
                            Text('Change Address', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _streetAddress,
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF2D3748)),
                ),
                Text(
                  _cityStateZip,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF4A5568)),
                ),
                const Divider(height: 24, color: Color(0xFFE2E8F0)),

                // Delivery Options / Estimated Dates
                Text(
                  'Choose Delivery Speed',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF718096)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _deliverySpeed = 'standard'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _deliverySpeed == 'standard' ? const Color(0xFFE6F4EA) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _deliverySpeed == 'standard' ? const Color(0xFF0D3B2E) : const Color(0xFFE2E8F0),
                              width: _deliverySpeed == 'standard' ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _deliverySpeed == 'standard' ? Icons.radio_button_checked : Icons.radio_button_off,
                                size: 16,
                                color: const Color(0xFF0D3B2E),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Standard Delivery', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748))),
                                    Text('2-3 business days', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF718096))),
                                  ],
                                ),
                              ),
                              Text('FREE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF22543D))),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _deliverySpeed = 'express'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _deliverySpeed == 'express' ? const Color(0xFFE6F4EA) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _deliverySpeed == 'express' ? const Color(0xFF0D3B2E) : const Color(0xFFE2E8F0),
                              width: _deliverySpeed == 'express' ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _deliverySpeed == 'express' ? Icons.radio_button_checked : Icons.radio_button_off,
                                size: 16,
                                color: const Color(0xFF0D3B2E),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Express Delivery', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748))),
                                    Text('Delivered Tomorrow', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF718096))),
                                  ],
                                ),
                              ),
                              Text('₹49', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedMeetupCard(Book book) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0D3B2E), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D3B2E).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.groups_outlined, color: Color(0xFF0D3B2E), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Peer-to-Peer Meetup',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D3B2E),
                    ),
                  ),
                ],
              ),
              if (!_isBorrow)
                InkWell(
                  onTap: () => setState(() => _currentStep = 1),
                  child: Text('Change Mode', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E))),
                ),
            ],
          ),
          Text(
            'Meet the book owner in person at a safe public location.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF718096)),
          ),
          const SizedBox(height: 16),

          // Meetup Details Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Meetup Details', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748))),
                const SizedBox(height: 12),

                // Owner Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFCBD5E0),
                      child: Text('R', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF2D3748))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Rahul Sharma', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748))),
                              const SizedBox(width: 6),
                              const Icon(Icons.star, size: 12, color: Color(0xFFD69E2E)),
                              Text(' 4.9 (32 reviews)', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096))),
                            ],
                          ),
                          Text('Member since Jan 2023 • 26 successful rentals', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF718096))),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening chat with Rahul Sharma...')));
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Message', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E))),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Preferred Meetup Location
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Preferred Meetup Location', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096))),
                          Text(_meetupLocation, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748))),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _showChangeMeetupDialog(),
                      child: Text('Change', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF0D3B2E))),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Preferred Date & Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Preferred Date & Time', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096))),
                          Text(_meetupDateTime, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748))),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _showChangeMeetupDialog(),
                      child: Text('Change', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF0D3B2E))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedDropoffCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0D3B2E), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D3B2E).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.handshake_outlined, color: Color(0xFF0D3B2E), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Owner Drop-off',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D3B2E),
                    ),
                  ),
                ],
              ),
              if (!_isBorrow)
                InkWell(
                  onTap: () => setState(() => _currentStep = 1),
                  child: Text('Change Mode', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E))),
                ),
            ],
          ),
          Text(
            'The book owner will drop off the book at your designated hub or security desk.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF718096)),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Drop-off Instructions', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.storefront_outlined, size: 16, color: Color(0xFF0D3B2E)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tactile Hub — Koramangala / Building Front Desk',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Book will be safely sealed and tagged with order #ORD-2026 for contactless pickup.',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: Color(0xFF718096)),
                    const SizedBox(width: 8),
                    Text(
                      'Ready for pickup within 24 hours of confirmation',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF2D3748)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChangeAddressDialog() {
    final nameCtrl = TextEditingController(text: _recipientName);
    final phoneCtrl = TextEditingController(text: _recipientPhone);
    final streetCtrl = TextEditingController(text: _streetAddress);
    final cityCtrl = TextEditingController(text: _cityStateZip);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF0D3B2E)),
              const SizedBox(width: 8),
              Text(
                'Change Delivery Address',
                style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E)),
              ),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            width: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choose a saved address or enter a new one:', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF718096))),
                  const SizedBox(height: 12),

                  // Quick Preset 1: Home
                  InkWell(
                    onTap: () {
                      setState(() {
                        _addressLabel = 'HOME';
                        _streetAddress = 'Flat 402, Green Valley Apartments, 12th Main Road';
                        _cityStateZip = 'Indiranagar, Bangalore, Karnataka - 560038';
                      });
                      Navigator.of(dialogCtx).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _addressLabel == 'HOME' ? const Color(0xFFF0FDF4) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _addressLabel == 'HOME' ? const Color(0xFF0D3B2E) : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.home, color: _addressLabel == 'HOME' ? const Color(0xFF0D3B2E) : const Color(0xFF718096), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Home (Default)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748))),
                                Text('Flat 402, Green Valley Apts, Indiranagar, Bangalore - 560038', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096))),
                              ],
                            ),
                          ),
                          if (_addressLabel == 'HOME') const Icon(Icons.check_circle, color: Color(0xFF0D3B2E), size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Quick Preset 2: Office
                  InkWell(
                    onTap: () {
                      setState(() {
                        _addressLabel = 'OFFICE';
                        _streetAddress = 'Cyber City, Phase 3, Tower C, 6th Floor';
                        _cityStateZip = 'Gurugram, Haryana - 122002';
                      });
                      Navigator.of(dialogCtx).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _addressLabel == 'OFFICE' ? const Color(0xFFF0FDF4) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _addressLabel == 'OFFICE' ? const Color(0xFF0D3B2E) : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.business, color: _addressLabel == 'OFFICE' ? const Color(0xFF0D3B2E) : const Color(0xFF718096), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Office', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748))),
                                Text('Cyber City, Phase 3, Tower C, Gurugram - 122002', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096))),
                              ],
                            ),
                          ),
                          if (_addressLabel == 'OFFICE') const Icon(Icons.check_circle, color: Color(0xFF0D3B2E), size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  Text('Or Enter Custom Address', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748))),
                  const SizedBox(height: 8),

                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Recipient Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneCtrl,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: streetCtrl,
                    decoration: InputDecoration(
                      labelText: 'Street / Building / Flat',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: cityCtrl,
                    decoration: InputDecoration(
                      labelText: 'City, State, Pincode',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF718096))),
            ),
            ElevatedButton(
              onPressed: () {
                if (streetCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    _addressLabel = 'CUSTOM';
                    _recipientName = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : _recipientName;
                    _recipientPhone = phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : _recipientPhone;
                    _streetAddress = streetCtrl.text.trim();
                    _cityStateZip = cityCtrl.text.trim().isNotEmpty ? cityCtrl.text.trim() : _cityStateZip;
                  });
                }
                Navigator.of(dialogCtx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D3B2E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Save & Use Address', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showChangeMeetupDialog() {
    final locationCtrl = TextEditingController(text: _meetupLocation);
    final timeCtrl = TextEditingController(text: _meetupDateTime);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.groups_outlined, color: Color(0xFF0D3B2E)),
              const SizedBox(width: 8),
              Text(
                'Change Meetup Details',
                style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: locationCtrl,
                decoration: InputDecoration(
                  labelText: 'Meetup Location',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeCtrl,
                decoration: InputDecoration(
                  labelText: 'Preferred Date & Time',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF718096))),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (locationCtrl.text.trim().isNotEmpty) {
                    _meetupLocation = locationCtrl.text.trim();
                  }
                  if (timeCtrl.text.trim().isNotEmpty) {
                    _meetupDateTime = timeCtrl.text.trim();
                  }
                });
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D3B2E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Update Details', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCollapsedAccordion({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedDeliveryMethod = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDF2F7)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF718096)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748)),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Text(
                'Select',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D3B2E),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 16, color: Color(0xFF0D3B2E)),
          ],
        ),
      ),
    );
  }

  // STEP 3: PAYMENT SELECTION (AMAZON-GRADE ACCORDION)
  Widget _buildStep3PaymentSelection(Book book) {
    final amountInr = (_totalPayable * 82.78).toStringAsFixed(2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Order Summary Confirmation Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEDF2F7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Summary',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D3B2E),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _currentStep = 2),
                    child: Text(
                      'Change',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0D3B2E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildSummaryRow('Mode & Duration', '${_getModeLabel(widget.mode)} • $_selectedDays Days (Due: $_formattedReturnDate)'),
              if (_isRental) ...[
                _buildSummaryRow('Rental Fee ($_selectedDays d)', '\$${_rentalFee.toStringAsFixed(2)} (Approx. ₹${(_rentalFee * 82.78).toStringAsFixed(0)})'),
                _buildSummaryRow('Security Deposit', '\$${_securityDeposit.toStringAsFixed(2)} (100% Refundable on return)'),
              ] else ...[
                _buildSummaryRow('Book Price', '\$${((widget.book?.price != null && widget.book!.price > 0 ? widget.book!.price : 18.00)).toStringAsFixed(2)}'),
              ],
              if (_selectedDeliveryMethod == 'delivery') ...[
                _buildSummaryRow('Delivery Option', 'Doorstep Delivery (${_deliverySpeed == 'express' ? 'Express' : 'Standard'})'),
                _buildSummaryRow('Shipping Address', '$_streetAddress, $_cityStateZip'),
                _buildSummaryRow('Recipient', '$_recipientName ($_recipientPhone)'),
                _buildSummaryRow('Estimated Delivery', _deliverySpeed == 'express' ? 'Tomorrow by 8:00 PM (+\$0.60 / ₹49)' : '2-3 Business Days (FREE)'),
              ] else if (_selectedDeliveryMethod == 'meetup') ...[
                _buildSummaryRow('Delivery Option', 'Peer-to-Peer Meetup (FREE)'),
                _buildSummaryRow('Meetup Location', _meetupLocation),
                _buildSummaryRow('Meetup Time', _meetupDateTime),
                _buildSummaryRow('Book Owner', '👤 Rahul Sharma ★ 4.9 (32 reviews)'),
              ] else ...[
                _buildSummaryRow('Delivery Option', 'Owner Drop-off (FREE)'),
                _buildSummaryRow('Drop-off Location', 'Tactile Hub — Front Security Desk'),
                _buildSummaryRow('Pickup Window', 'Within 24 Hours of Confirmation'),
              ],
              const Divider(height: 16, color: Color(0xFFE2E8F0)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Payable', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E))),
                  Text(
                    '\$${_totalPayable.toStringAsFixed(2)} (Approx. ₹$amountInr)',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // 2. Header: "Select a payment method"
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Select a payment method',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0D3B2E),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF15803D)),
                const SizedBox(width: 4),
                Text(
                  '100% Secure',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF15803D)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Transactions are encrypted with bank-grade 256-bit SSL & RBI escrow security.',
          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096)),
        ),
        const SizedBox(height: 14),

        // 3. Amazon-Style Unified Accordion Container
        _buildUnifiedPaymentAccordion(book, amountInr),
        const SizedBox(height: 24),

        // 4. Primary Dynamic CTA Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isProcessingPayment ? null : () => _executeOrderPayment(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D3B2E),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF0D3B2E).withValues(alpha: 0.6),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isProcessingPayment
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Securing Payment...',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedPaymentMethod == 'cod' ? Icons.local_shipping_outlined : Icons.lock_outline,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _getPrimaryCtaButtonLabel(amountInr),
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 14),

        // 5. Bank-Grade Trust Badges Footer
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTrustFeature(Icons.lock_outline, '256-Bit SSL', 'Encrypted'),
              Container(width: 1, height: 22, color: const Color(0xFFE2E8F0)),
              _buildTrustFeature(Icons.verified_user_outlined, '100% Escrow', 'Protected'),
              Container(width: 1, height: 22, color: const Color(0xFFE2E8F0)),
              _buildTrustFeature(Icons.account_balance_outlined, 'RBI & NPCI', 'Compliant'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            _isRental
                ? 'Security deposit (\$15.00 / ₹1,241.70) automatically released upon book return inspection.'
                : 'Free cancellation & instant refund before shipment confirmation.',
            style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildTrustFeature(IconData icon, String title, String subtitle) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF0D3B2E)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
          ],
        ),
      ],
    );
  }

  String _getPrimaryCtaButtonLabel(String amountInr) {
    switch (_selectedPaymentMethod) {
      case 'upi':
        if (_upiSubMethod == 'apps') {
          return 'Pay ₹$amountInr via ${_getUpiAppName(_selectedUpiApp)} (US \$${_totalPayable.toStringAsFixed(2)})';
        } else if (_upiSubMethod == 'qr') {
          return 'Pay ₹$amountInr via QR Code (US \$${_totalPayable.toStringAsFixed(2)})';
        } else {
          return 'Request ₹$amountInr via UPI ID (US \$${_totalPayable.toStringAsFixed(2)})';
        }
      case 'card':
        final brand = _detectCardBrand(_cardNumberController.text);
        final brandLabel = brand.isNotEmpty ? ' $brand' : '';
        return 'Pay ₹$amountInr with$brandLabel Card (US \$${_totalPayable.toStringAsFixed(2)})';
      case 'netbanking':
        return 'Proceed to $_selectedBank (₹$amountInr)';
      case 'wallet':
        return 'Pay ₹$amountInr via ${_getWalletDisplayName(_selectedWallet)}';
      case 'cod':
        return 'Place Order (Pay on Delivery / Hub)';
      default:
        return 'Pay ₹$amountInr (US \$${_totalPayable.toStringAsFixed(2)})';
    }
  }

  Future<void> _executeOrderPayment() async {
    setState(() => _isProcessingPayment = true);
    final bookId = int.tryParse(widget.book?.id ?? '1') ?? 1;
    final mode = widget.mode.toLowerCase().contains('rent') ? 'rental' : 'purchase';
    final shippingAddress = '$_streetAddress, $_cityStateZip';
    final isCod = _selectedPaymentMethod == 'cod';

    try {
      final orderRes = await ApiService.createPaymentOrder(
        _selectedPaymentMethod,
        shippingAddress,
        mode: mode,
        bookId: bookId,
        rentalDays: _selectedDays,
      );

      if (!mounted) return;

      if (isCod || orderRes['is_cod'] == true) {
        if (mounted) {
          setState(() {
            _isProcessingPayment = false;
            _placedOrderId = orderRes['order_id'];
            _isOrderSuccess = true;
          });
        }
        return;
      }

      // Online payment via Razorpay
      final rzpOrderId = orderRes['razorpay_order_id'] as String?;
      final keyId = orderRes['key_id'] as String?;
      final amountPaise = (orderRes['amount'] as num?)?.toInt() ?? ((_totalPayable * 100).toInt());

      if (rzpOrderId == null || keyId == null || keyId.isEmpty) {
        throw Exception("Invalid payment configuration returned by server");
      }

      final result = await PaymentGatewayService.openCheckout(
        keyId: keyId,
        orderId: rzpOrderId,
        amountPaise: amountPaise,
        userEmail: ApiService.token != null ? 'customer@tactilearchive.com' : 'guest@tactilearchive.com',
        userPhone: _recipientPhone,
        userName: _recipientName,
        description: widget.book?.title ?? 'LibriFlow Checkout',
      );

      if (!mounted) return;

      if (result.isCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment cancelled. You can retry whenever you are ready.'),
            backgroundColor: Color(0xFFC05621),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      if (!result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${result.errorMessage ?? "Transaction could not be completed."}'),
            backgroundColor: const Color(0xFF991B1B),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Verify payment with backend
      final verificationRes = await ApiService.verifyPaymentDetailed(
        result.razorpayOrderId ?? rzpOrderId,
        result.razorpayPaymentId ?? '',
        result.razorpaySignature ?? '',
      );

      if (!mounted) return;

      if (verificationRes['reconciliation'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Stock Unavailable — Refund Pending'),
            content: Text(
              verificationRes['message']?.toString() ??
                  'Payment was captured, but the requested book is no longer in stock. '
                  'A full refund has been initiated to your original payment method.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/order-history');
                },
                child: const Text('View Orders'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/browse');
                },
                child: const Text('Browse Books'),
              ),
            ],
          ),
        );
        return;
      }

      if (verificationRes['success'] == true ||
          verificationRes['message'] == 'Payment verified successfully') {
        setState(() {
          _placedOrderId = verificationRes['order_id'];
          _isOrderSuccess = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              verificationRes['message']?.toString() ??
                  'Payment verification failed. Please contact support if amount was debited.',
            ),
            backgroundColor: const Color(0xFF991B1B),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout encountered an error: $e'),
          backgroundColor: const Color(0xFF991B1B),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
    }
  }

  Widget _buildUnifiedPaymentAccordion(Book book, String amountInr) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // 1. UPI & QR Code (Recommended)
            _buildPaymentAccordionItem(
              id: 'upi',
              title: 'UPI & Instant Apps',
              subtitle: 'Google Pay, PhonePe, Paytm, BHIM & QR Code',
              badge: 'RECOMMENDED',
              badgeColor: const Color(0xFF15803D),
              badgeBg: const Color(0xFFDCFCE7),
              brandWidgets: [
                _buildBrandBadge('GPay', const Color(0xFF4285F4)),
                _buildBrandBadge('PhonePe', const Color(0xFF5F259F)),
                _buildBrandBadge('Paytm', const Color(0xFF002E6E)),
                _buildBrandBadge('BHIM', const Color(0xFF00796B)),
              ],
              isExpanded: _selectedPaymentMethod == 'upi',
              expandedContent: _buildAmazonUpiExpanded(book, amountInr),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEDF2F7)),

            // 2. Credit or Debit Card
            _buildPaymentAccordionItem(
              id: 'card',
              title: 'Credit or Debit Card',
              subtitle: 'Visa, Mastercard, RuPay & more',
              brandWidgets: [
                _buildBrandBadge('VISA', const Color(0xFF1A1F71)),
                _buildBrandBadge('Mastercard', const Color(0xFFEB001B)),
                _buildBrandBadge('RuPay', const Color(0xFF097939)),
              ],
              isExpanded: _selectedPaymentMethod == 'card',
              expandedContent: _buildAmazonCardExpanded(amountInr),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEDF2F7)),

            // 3. Net Banking
            _buildPaymentAccordionItem(
              id: 'netbanking',
              title: 'Net Banking',
              subtitle: 'Direct transfer from 50+ Indian banks',
              brandWidgets: [
                _buildBrandBadge('HDFC', const Color(0xFF004C8F)),
                _buildBrandBadge('SBI', const Color(0xFF280071)),
                _buildBrandBadge('ICICI', const Color(0xFFB02A30)),
              ],
              isExpanded: _selectedPaymentMethod == 'netbanking',
              expandedContent: _buildAmazonNetBankingExpanded(),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEDF2F7)),

            // 4. Wallets & Amazon Pay
            _buildPaymentAccordionItem(
              id: 'wallet',
              title: 'Wallets & Amazon Pay',
              subtitle: 'LibriFlow Escrow, Amazon Pay, Paytm & PhonePe',
              brandWidgets: [
                _buildBrandBadge('Amazon Pay', const Color(0xFFFF9900), textColor: Colors.black87),
                _buildBrandBadge('Paytm', const Color(0xFF002E6E)),
              ],
              isExpanded: _selectedPaymentMethod == 'wallet',
              expandedContent: _buildAmazonWalletExpanded(amountInr),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEDF2F7)),

            // 5. Pay on Delivery / Hub Handoff (COD)
            _buildPaymentAccordionItem(
              id: 'cod',
              title: 'Pay on Delivery / Hub Handoff',
              subtitle: 'Pay via Cash or UPI upon physical receipt',
              badge: 'NO EXTRA CHARGE',
              badgeColor: const Color(0xFF15803D),
              badgeBg: const Color(0xFFDCFCE7),
              isExpanded: _selectedPaymentMethod == 'cod',
              expandedContent: _buildAmazonCodExpanded(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentAccordionItem({
    required String id,
    required String title,
    required String subtitle,
    String? badge,
    Color? badgeColor,
    Color? badgeBg,
    List<Widget>? brandWidgets,
    required bool isExpanded,
    required Widget expandedContent,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      color: isExpanded ? const Color(0xFFF9FBFA) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          InkWell(
            onTap: () => setState(() => _selectedPaymentMethod = id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Radio Indicator
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isExpanded ? const Color(0xFF0D3B2E) : const Color(0xFFCBD5E1),
                        width: isExpanded ? 6 : 2,
                      ),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title + Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isExpanded ? const Color(0xFF0D3B2E) : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            if (badge != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: badgeBg ?? const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: (badgeColor ?? const Color(0xFF15803D)).withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  badge,
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: badgeColor ?? const Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  if (brandWidgets != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: brandWidgets,
                    ),
                ],
              ),
            ),
          ),
          // Expanded Content
          if (isExpanded) ...[
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: expandedContent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmazonUpiExpanded(Book book, String amountInr) {
    final minutes = (_qrCountdownSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_qrCountdownSeconds % 60).toString().padLeft(2, '0');
    final qrApiUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=240x240&margin=6&data=upi%3A%2F%2Fpay%3Fpa%3Dtactile.escrow%40icici%26pn%3DTactile%20Archive%26am%3D$amountInr%26cu%3DINR%26tn%3DLibriFlow%20Order';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-method Segmented Pills
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF2F7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _buildUpiPill('apps', '⚡ Instant Apps', Icons.flash_on),
              _buildUpiPill('qr', '📱 Scan QR Code', Icons.qr_code_2),
              _buildUpiPill('vpa', '✍️ UPI ID / VPA', Icons.alternate_email),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // SUB-VIEW 1: INSTANT APPS GRID
        if (_upiSubMethod == 'apps') ...[
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.1,
            children: [
              _buildUpiAppCard(
                id: 'gpay',
                name: 'Google Pay',
                subtitle: 'Instant approval',
                badgeText: 'GPay',
                badgeColor: const Color(0xFF4285F4),
              ),
              _buildUpiAppCard(
                id: 'phonepe',
                name: 'PhonePe',
                subtitle: 'Direct debit',
                badgeText: 'PhonePe',
                badgeColor: const Color(0xFF5F259F),
              ),
              _buildUpiAppCard(
                id: 'paytm',
                name: 'Paytm UPI',
                subtitle: 'Fast 1-tap pay',
                badgeText: 'Paytm',
                badgeColor: const Color(0xFF002E6E),
              ),
              _buildUpiAppCard(
                id: 'bhim',
                name: 'BHIM UPI',
                subtitle: 'NPCI verified',
                badgeText: 'BHIM',
                badgeColor: const Color(0xFF00796B),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD1E7DD)),
            ),
            child: Row(
              children: [
                const Icon(Icons.touch_app_outlined, size: 16, color: Color(0xFF0D3B2E)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'On clicking "Pay" below, your ${_getUpiAppName(_selectedUpiApp)} app will open directly with ₹$amountInr pre-filled.',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF0D3B2E)),
                  ),
                ),
              ],
            ),
          ),
        ],

        // SUB-VIEW 2: SCAN QR CODE
        if (_upiSubMethod == 'qr') ...[
          Center(
            child: Column(
              children: [
                // QR Box with Viewfinder Frame
                Container(
                  width: 190,
                  height: 190,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(170, 170),
                        painter: _QrViewfinderPainter(color: const Color(0xFF0D3B2E)),
                      ),
                      Image.network(
                        qrApiUrl,
                        width: 145,
                        height: 145,
                        fit: BoxFit.contain,
                        loadingBuilder: (c, child, progress) {
                          if (progress == null) return child;
                          return CustomPaint(
                            size: const Size(145, 145),
                            painter: _CustomQrPainter(),
                          );
                        },
                        errorBuilder: (c, e, s) => CustomPaint(
                          size: const Size(145, 145),
                          painter: _CustomQrPainter(),
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF0D3B2E), width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '₹',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0D3B2E),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Countdown Timer Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 13, color: Color(0xFF92400E)),
                      const SizedBox(width: 4),
                      Text(
                        'QR expires in $minutes:$seconds',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF92400E)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Copy UPI ID Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('UPI ID: ', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                      Text('tactile.escrow@icici', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(const ClipboardData(text: 'tactile.escrow@icici'));
                          setState(() => _isUpiIdCopied = true);
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) setState(() => _isUpiIdCopied = false);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _isUpiIdCopied ? const Color(0xFFDCFCE7) : const Color(0xFFEDF2F7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _isUpiIdCopied ? '✓ Copied' : 'Copy',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _isUpiIdCopied ? const Color(0xFF15803D) : const Color(0xFF0D3B2E),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Enlarge QR Button
                TextButton.icon(
                  onPressed: () => _showFullscreenQrDialog(book),
                  icon: const Icon(Icons.fullscreen, size: 16, color: Color(0xFF0D3B2E)),
                  label: Text('Enlarge QR Code', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E))),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                ),
              ],
            ),
          ),
        ],

        // SUB-VIEW 3: ENTER UPI ID / VPA
        if (_upiSubMethod == 'vpa') ...[
          Text('Enter your UPI ID / VPA', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748))),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _upiVpaController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.alternate_email, size: 16, color: Color(0xFF718096)),
                    hintText: 'mobile@upi or username@bank',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA0AEC0)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0D3B2E), width: 1.5)),
                  ),
                  style: GoogleFonts.inter(fontSize: 12.5),
                  onChanged: (val) {
                    if (_isVpaVerified) {
                      setState(() {
                        _isVpaVerified = false;
                        _vpaVerifiedName = null;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: () {
                    if (_upiVpaController.text.trim().isNotEmpty) {
                      setState(() {
                        _isVpaVerified = true;
                        _vpaVerifiedName = 'Arjun Sharma (NPCI Verified)';
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isVpaVerified ? const Color(0xFF15803D) : const Color(0xFF0D3B2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Text(_isVpaVerified ? '✓ Verified' : 'Verify', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          if (_isVpaVerified) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 14, color: Color(0xFF15803D)),
                  const SizedBox(width: 6),
                  Text('Verified: ${_vpaVerifiedName ?? "Arjun Sharma"} • Escrow Protected', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF15803D))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          // Quick Handle Chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: ['@oksbi', '@okhdfcbank', '@paytm', '@ybl', '@icici', '@axl'].map((handle) {
              return InkWell(
                onTap: () {
                  final current = _upiVpaController.text.split('@').first;
                  _upiVpaController.text = '${current.isEmpty ? 'user' : current}$handle';
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(handle, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            'A payment request will be sent to your UPI app. Open and approve within 5 minutes.',
            style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF718096)),
          ),
        ],
      ],
    );
  }

  Widget _buildUpiPill(String id, String label, IconData icon) {
    final isSelected = _upiSubMethod == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _upiSubMethod = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? const Color(0xFF0D3B2E) : const Color(0xFF64748B)),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF0D3B2E) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpiAppCard({
    required String id,
    required String name,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
  }) {
    final isSelected = _selectedUpiApp == id;
    return InkWell(
      onTap: () => setState(() => _selectedUpiApp = id),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF1F8F5) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D3B2E) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: badgeColor),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(name, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: isSelected ? const Color(0xFF0D3B2E) : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmazonCardExpanded(String amountInr) {
    final detectedBrand = _detectCardBrand(_cardNumberController.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card Number
        Text('Card Number', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
        const SizedBox(height: 5),
        TextField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          maxLength: 19,
          buildCounter: (ctx, {required currentLength, required isFocused, maxLength}) => null,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.credit_card, size: 18, color: Color(0xFF64748B)),
            suffixIcon: detectedBrand.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildBrandBadge(
                      detectedBrand,
                      detectedBrand == 'Visa'
                          ? const Color(0xFF1A1F71)
                          : (detectedBrand == 'Mastercard' ? const Color(0xFFEB001B) : const Color(0xFF097939)),
                    ),
                  )
                : null,
            hintText: 'XXXX  XXXX  XXXX  XXXX',
            hintStyle: GoogleFonts.inter(fontSize: 12.5, letterSpacing: 1.5, color: const Color(0xFF94A3B8)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0D3B2E), width: 1.5)),
          ),
          style: GoogleFonts.inter(fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.w600),
          onChanged: (val) {
            final clean = val.replaceAll(' ', '');
            final buffer = StringBuffer();
            for (int i = 0; i < clean.length; i++) {
              buffer.write(clean[i]);
              if ((i + 1) % 4 == 0 && i + 1 != clean.length) buffer.write(' ');
            }
            final formatted = buffer.toString();
            if (formatted != val) {
              _cardNumberController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
            setState(() {});
          },
        ),
        const SizedBox(height: 12),

        // Name on Card
        Text('Name on Card', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
        const SizedBox(height: 5),
        TextField(
          controller: _cardHolderController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.person_outline, size: 18, color: Color(0xFF64748B)),
            hintText: 'e.g. Arjun Sharma',
            hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0D3B2E), width: 1.5)),
          ),
          style: GoogleFonts.inter(fontSize: 12.5),
        ),
        const SizedBox(height: 12),

        // Expiry Date & CVV Row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Expiry Date', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _cardExpiryController,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    buildCounter: (ctx, {required currentLength, required isFocused, maxLength}) => null,
                    decoration: InputDecoration(
                      hintText: 'MM / YY',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0D3B2E), width: 1.5)),
                    ),
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                    onChanged: (val) {
                      if (val.length == 2 && !_cardExpiryController.text.contains('/')) {
                        _cardExpiryController.value = TextEditingValue(
                          text: '$val/',
                          selection: const TextSelection.collapsed(offset: 3),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('CVV / CVC', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
                      const SizedBox(width: 4),
                      const Tooltip(
                        message: '3 digits on back of card',
                        child: Icon(Icons.info_outline, size: 13, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _cardCvvController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    buildCounter: (ctx, {required currentLength, required isFocused, maxLength}) => null,
                    decoration: InputDecoration(
                      hintText: '•••',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0D3B2E), width: 1.5)),
                    ),
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Save card checkbox
        InkWell(
          onTap: () => setState(() => _saveCardForFuture = !_saveCardForFuture),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _saveCardForFuture,
                  activeColor: const Color(0xFF0D3B2E),
                  onChanged: (val) => setState(() => _saveCardForFuture = val ?? true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Securely save card as per RBI tokenization guidelines',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF475569)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmazonNetBankingExpanded() {
    final popularBanks = [
      {'id': 'HDFC', 'name': 'HDFC Bank', 'color': const Color(0xFF004C8F)},
      {'id': 'SBI', 'name': 'SBI', 'color': const Color(0xFF280071)},
      {'id': 'ICICI', 'name': 'ICICI Bank', 'color': const Color(0xFFB02A30)},
      {'id': 'AXIS', 'name': 'Axis Bank', 'color': const Color(0xFF861F41)},
      {'id': 'KOTAK', 'name': 'Kotak', 'color': const Color(0xFFDA251C)},
      {'id': 'PNB', 'name': 'PNB', 'color': const Color(0xFFA20000)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('POPULAR BANKS', style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: const Color(0xFF64748B))),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.8,
          children: popularBanks.map((bank) {
            final isSelected = _selectedBank == bank['id'];
            final color = bank['color'] as Color;
            return InkWell(
              onTap: () => setState(() => _selectedBank = bank['id'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF1F8F5) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0D3B2E) : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      bank['id'] as String,
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: color),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bank['name'] as String,
                      style: GoogleFonts.inter(fontSize: 9.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: const Color(0xFF334155)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        Text('OR OTHER BANKS', style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: const Color(0xFF64748B))),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _selectedOtherBank,
          hint: Text('Choose from 50+ other Indian banks', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
          isExpanded: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0D3B2E), width: 1.5)),
          ),
          items: _kOtherBanks.map((bank) {
            return DropdownMenuItem<String>(
              value: bank,
              child: Text(bank, style: GoogleFonts.inter(fontSize: 12)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedOtherBank = val;
                _selectedBank = val;
              });
            }
          },
        ),
        const SizedBox(height: 10),
        Text(
          'You will be redirected to your bank portal for secure 2-factor OTP authorization.',
          style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF718096)),
        ),
      ],
    );
  }

  Widget _buildAmazonWalletExpanded(String amountInr) {
    final wallets = [
      {'id': 'amazon_pay', 'name': 'Amazon Pay Wallet', 'subtitle': '1-click instant checkout', 'badge': 'Amazon', 'badgeColor': const Color(0xFFFF9900)},
      {'id': 'paytm_wallet', 'name': 'Paytm Wallet', 'subtitle': 'Zero transaction fee', 'badge': 'Paytm', 'badgeColor': const Color(0xFF002E6E)},
      {'id': 'phonepe_wallet', 'name': 'PhonePe Wallet', 'subtitle': 'Link & pay via OTP', 'badge': 'PhonePe', 'badgeColor': const Color(0xFF5F259F)},
      {'id': 'mobikwik', 'name': 'MobiKwik ZIP / Wallet', 'subtitle': 'Pay later or wallet balance', 'badge': 'MobiKwik', 'badgeColor': const Color(0xFF0091FF)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LibriFlow Escrow Balance Quick Toggle (Amazon Pay Balance style)
        InkWell(
          onTap: () => setState(() => _useEscrowBalance = !_useEscrowBalance),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _useEscrowBalance ? const Color(0xFFF1F8F5) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _useEscrowBalance ? const Color(0xFF0D3B2E) : const Color(0xFFE2E8F0),
                width: _useEscrowBalance ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _useEscrowBalance,
                    activeColor: const Color(0xFF0D3B2E),
                    onChanged: (val) => setState(() => _useEscrowBalance = val ?? true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Use Escrow Balance: ₹350.00 Available', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E))),
                      Text(_useEscrowBalance ? '₹350.00 applied towards security deposit / order' : 'Tap to apply available balance', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'ESCROW',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF15803D)),
                  ),
                ),
              ],
            ),
          ),
        ),

        Text('EXTERNAL WALLETS', style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: const Color(0xFF64748B))),
        const SizedBox(height: 8),

        Column(
          children: wallets.map((w) {
            final isSelected = _selectedWallet == w['id'];
            final badgeColor = w['badgeColor'] as Color;
            return InkWell(
              onTap: () => setState(() => _selectedWallet = w['id'] as String),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF1F8F5) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0D3B2E) : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        w['badge'] as String,
                        style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.bold, color: badgeColor),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w['name'] as String, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                          Text(w['subtitle'] as String, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      size: 16,
                      color: isSelected ? const Color(0xFF0D3B2E) : const Color(0xFFCBD5E1),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Text(
          'Instant 1-click checkout with secure 2-factor OTP verification.',
          style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF718096)),
        ),
      ],
    );
  }

  Widget _buildAmazonCodExpanded() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, size: 18, color: Color(0xFF15803D)),
              const SizedBox(width: 8),
              Text(
                'Pay upon Physical Delivery / Hub Handoff',
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF166534)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildCodBullet('Inspect the book in person before handing over payment.'),
          _buildCodBullet('Exact cash or UPI QR scan accepted by delivery partner / peer.'),
          _buildCodBullet('Digital handoff OTP generated instantly upon order placement.'),
          if (_isRental)
            _buildCodBullet('Refundable deposit (\$15.00 / ₹1,241.70) held in escrow receipt.'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '✓ ZERO EXTRA CASH-ON-DELIVERY CONVENIENCE FEE',
              style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF15803D)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(text, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF166534))),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096))),
          ),
          Expanded(
            child: Text(val, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748))),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandBadge(String label, Color color, {Color? textColor}) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: textColor ?? color,
        ),
      ),
    );
  }

  String _getUpiAppName(String appKey) {
    switch (appKey) {
      case 'gpay': return 'Google Pay';
      case 'phonepe': return 'PhonePe';
      case 'paytm': return 'Paytm';
      case 'bhim': return 'BHIM UPI';
      default: return 'UPI';
    }
  }

  String _getWalletDisplayName(String walletKey) {
    switch (walletKey) {
      case 'libri_escrow': return 'Escrow Wallet';
      case 'amazon_pay': return 'Amazon Pay';
      case 'paytm_wallet': return 'Paytm';
      case 'phonepe_wallet': return 'PhonePe';
      default: return 'Wallet';
    }
  }

  String _detectCardBrand(String number) {
    final clean = number.replaceAll(' ', '');
    if (clean.startsWith('4')) return 'Visa';
    if (clean.startsWith('51') || clean.startsWith('52') || clean.startsWith('53') || clean.startsWith('54') || clean.startsWith('55')) return 'Mastercard';
    if (clean.startsWith('60') || clean.startsWith('65') || clean.startsWith('81') || clean.startsWith('82') || clean.startsWith('508')) return 'RuPay';
    if (clean.startsWith('34') || clean.startsWith('37')) return 'Amex';
    return '';
  }

  static const List<String> _kOtherBanks = [
    'Bank of Baroda',
    'Canara Bank',
    'Union Bank of India',
    'IndusInd Bank',
    'Federal Bank',
    'IDFC FIRST Bank',
    'Yes Bank',
    'Bank of India',
    'Central Bank of India',
    'Indian Bank',
    'Indian Overseas Bank',
    'UCO Bank',
    'South Indian Bank',
    'Karur Vysya Bank',
    'RBL Bank',
    'AU Small Finance Bank',
    'Bandhan Bank',
    'City Union Bank',
    'DBS Bank India',
    'Jammu & Kashmir Bank',
    'Karnataka Bank',
    'Punjab & Sind Bank',
    'Standard Chartered Bank',
  ];

  void _showFullscreenQrDialog(Book book) {
    final amountInr = (_totalPayable * 82.78).toStringAsFixed(2);
    final qrApiUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=260x260&margin=6&data=upi%3A%2F%2Fpay%3Fpa%3Dtactile.escrow%40icici%26pn%3DTactile%20Archive%26am%3D$amountInr%26cu%3DINR%26tn%3DLibriFlow%20Order';

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Scan to Pay with UPI',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D3B2E),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogCtx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: 240,
                height: 240,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(212, 212),
                      painter: _QrViewfinderPainter(color: const Color(0xFF0D3B2E)),
                    ),
                    Image.network(
                      qrApiUrl,
                      width: 190,
                      height: 190,
                      fit: BoxFit.contain,
                      loadingBuilder: (c, child, progress) {
                        if (progress == null) return child;
                        return CustomPaint(
                          size: const Size(190, 190),
                          painter: _CustomQrPainter(),
                        );
                      },
                      errorBuilder: (c, e, s) => CustomPaint(
                        size: const Size(190, 190),
                        painter: _CustomQrPainter(),
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0D3B2E), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '₹',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0D3B2E),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '₹$amountInr',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0D3B2E),
                ),
              ),
              Text(
                'Pay exact amount • Escrow Protected',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF718096)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    setState(() => _isOrderSuccess = true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D3B2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('I Have Completed Payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ORDER / BORROW SUCCESS CONFIRMATION SCREEN
  Widget _buildSuccessScreen(Book book) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFC6F6D5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isBorrow ? Icons.mark_email_read_outlined : Icons.check,
                  size: 32,
                  color: const Color(0xFF22543D),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isBorrow ? 'Delivery Address Confirmed!' : 'Order Placed Successfully!',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D3B2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isBorrow
                    ? 'Your address has been securely shared with Rahul Sharma for request #REQ-2026-8941 ("${book.title}").'
                    : 'Your ${_getModeLabel(widget.mode).toLowerCase()} order #${_placedOrderId ?? 'ORD'} for "${book.title}" has been placed.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4A5568)),
              ),
              const SizedBox(height: 20),

              // Breakdown box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _selectedDeliveryMethod == 'delivery'
                              ? Icons.local_shipping_outlined
                              : _selectedDeliveryMethod == 'meetup'
                                  ? Icons.groups_outlined
                                  : Icons.handshake_outlined,
                          size: 18,
                          color: const Color(0xFF0D3B2E),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedDeliveryMethod == 'delivery'
                              ? 'Doorstep Delivery'
                              : _selectedDeliveryMethod == 'meetup'
                                  ? 'Peer-to-Peer Meetup'
                                  : 'Owner Drop-off',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _isBorrow ? 'Handover Scheduled' : 'Confirmed',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF166534)),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16, color: Color(0xFFE2E8F0)),

                    if (_isBorrow || _isRental) ...[
                      Text(
                        'Period: $_selectedDays Days • Return by $_formattedReturnDate',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B2E)),
                      ),
                      const SizedBox(height: 4),
                    ],

                    if (_isBorrow) ...[
                      Text(
                        'Book Owner: Rahul Sharma ★ 4.9',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2D3748)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Platform Fee: FREE (\$0.00 / ₹0)',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF166534)),
                      ),
                    ],

                    if (_selectedDeliveryMethod == 'delivery') ...[
                      const SizedBox(height: 6),
                      Text(
                        'Deliver To: $_recipientName ($_recipientPhone)',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2D3748)),
                      ),
                      Text(
                        '$_streetAddress, $_cityStateZip',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096)),
                      ),
                      Text(
                        'Estimated Dispatch: Tomorrow by 12:00 PM',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF22543D)),
                      ),
                    ] else if (_selectedDeliveryMethod == 'meetup') ...[
                      const SizedBox(height: 6),
                      Text(
                        'Meetup with: Rahul Sharma ★ 4.9',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2D3748)),
                      ),
                      Text(
                        'Location: $_meetupLocation',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096)),
                      ),
                      Text(
                        'Time: $_meetupDateTime',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF22543D)),
                      ),
                    ] else ...[
                      const SizedBox(height: 6),
                      Text(
                        'Pickup Hub: Tactile Hub — Koramangala / Front Security Desk',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2D3748)),
                      ),
                      Text(
                        'Ready for pickup within 24 hours of confirmation.',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096)),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/order-history'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0D3B2E),
                        side: const BorderSide(color: Color(0xFF0D3B2E)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('View in Orders', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.go('/browse'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D3B2E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Back to Catalog', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _QrViewfinderPainter extends CustomPainter {
  final Color color;
  _QrViewfinderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 20.0;

    // Top Left
    canvas.drawLine(const Offset(0, cornerLength), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);

    // Top Right
    canvas.drawLine(Offset(size.width - cornerLength, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Bottom Left
    canvas.drawLine(Offset(0, size.height - cornerLength), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);

    // Bottom Right
    canvas.drawLine(Offset(size.width - cornerLength, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - cornerLength), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CustomQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A202C)
      ..style = PaintingStyle.fill;

    final double moduleSize = size.width / 25.0;

    void drawModule(int col, int row) {
      canvas.drawRect(
        Rect.fromLTWH(col * moduleSize, row * moduleSize, moduleSize - 0.5, moduleSize - 0.5),
        paint,
      );
    }

    void drawFinderPattern(int startCol, int startRow) {
      for (int r = 0; r < 7; r++) {
        for (int c = 0; c < 7; c++) {
          if (r == 0 || r == 6 || c == 0 || c == 6 || (r >= 2 && r <= 4 && c >= 2 && c <= 4)) {
            drawModule(startCol + c, startRow + r);
          }
        }
      }
    }

    // Top-Left Finder
    drawFinderPattern(0, 0);
    // Top-Right Finder
    drawFinderPattern(18, 0);
    // Bottom-Left Finder
    drawFinderPattern(0, 18);

    // Alignment Pattern at (16, 16)
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 5; c++) {
        if (r == 0 || r == 4 || c == 0 || c == 4 || (r == 2 && c == 2)) {
          drawModule(16 + c, 16 + r);
        }
      }
    }

    // Timing Patterns (row 6 and col 6)
    for (int i = 7; i < 18; i += 2) {
      drawModule(i, 6);
      drawModule(6, i);
    }

    // Deterministic Data Modules
    final pattern = [
      0x5A, 0xA5, 0x3C, 0xC3, 0x69, 0x96, 0x0F, 0xF0,
      0x4B, 0xB4, 0x2D, 0xD2, 0x7E, 0xE7, 0x18, 0x81,
      0x36, 0x63, 0x55, 0xAA, 0x12, 0x21, 0x77, 0xEE, 0x99
    ];

    for (int r = 0; r < 25; r++) {
      for (int c = 0; c < 25; c++) {
        if (r <= 7 && c <= 7) continue;
        if (r <= 7 && c >= 17) continue;
        if (r >= 17 && c <= 7) continue;
        if (r >= 16 && r <= 20 && c >= 16 && c <= 20) continue;
        if (r == 6 || c == 6) continue;
        if (r >= 10 && r <= 14 && c >= 10 && c <= 14) continue;

        final byteVal = pattern[(r * 3 + c) % pattern.length];
        if (((byteVal >> ((r + c) % 8)) & 1) == 1) {
          drawModule(c, r);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
