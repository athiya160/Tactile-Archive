import 'package:libri_flow/core/widgets/ivory_scaffold.dart';
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/welcome_to_rent_dialog.dart';
import '../../../home/data/models/book_model.dart';
import '../../../home/domain/entities/book.dart';
import '../bloc/book_details_bloc.dart';
import '../bloc/book_details_event.dart';
import '../bloc/book_details_state.dart';
import '../widgets/book_images_section.dart';
import '../widgets/book_info_section.dart';
import '../widgets/book_action_card.dart';
import '../widgets/related_books_section.dart';
import '../widgets/book_reviews_section.dart';
import '../../../../core/widgets/tactile_footer.dart';
import '../../../../core/design_system/design_system.dart';

class BookDetailsPage extends StatelessWidget {
  const BookDetailsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookDetailsBloc, BookDetailsState>(
      listener: (context, state) {
        if (state is BookDetailsLoaded && state.successMessage != null) {
          final isBorrow = state.successMessage!.contains('Borrow request');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: DSColors.deepForestGreen,
              behavior: SnackBarBehavior.floating,
              action: isBorrow
                  ? null
                  : SnackBarAction(
                      label: 'VIEW CART',
                      textColor: Colors.white70,
                      onPressed: () => context.go('/cart'),
                    ),
            ),
          );
          if (!isBorrow) {
            context.read<CartBloc>().add(CartStarted());
          }
          context.read<BookDetailsBloc>().add(
            BookDetailsStarted(state.book.id),
          );
        }
      },
      builder: (context, state) {
        if (state is BookDetailsInitial || state is BookDetailsLoading) {
          return const IvoryScaffold(
            showAppBar: false,
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: DSColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Loading book listing...',
                      style: TextStyle(color: DSColors.charcoal, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (state is BookDetailsError) {
          return IvoryScaffold(
            showAppBar: false,
            body: Center(
              child: DSErrorState(
                title: 'Listing Unavailable',
                message: state.message.isNotEmpty
                    ? state.message
                    : 'This book listing is no longer available or is currently under review.',
                retryLabel: 'Back to Catalog',
                onRetry: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/browse');
                  }
                },
              ),
            ),
          );
        }
        if (state is BookDetailsLoaded) {
          return IvoryScaffold(
            showAppBar: false,
            body: BookDetailsContent(
              book: state.book,
              isFavorite: state.isFavorite,
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class BookDetailsContent extends StatefulWidget {
  final Book book;
  final bool isFavorite;
  const BookDetailsContent({
    super.key,
    required this.book,
    required this.isFavorite,
  });
  @override
  State<BookDetailsContent> createState() => _BookDetailsContentState();
}

class _BookDetailsContentState extends State<BookDetailsContent> {
  List<Book> _relatedBooks = [];
  bool _isLoadingRelated = true;
  @override
  void initState() {
    super.initState();
    _fetchRelatedBooks();
    _saveAndLoadRecentlyViewed();
  }

  @override
  void didUpdateWidget(BookDetailsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.id != widget.book.id) {
      setState(() {
        _isLoadingRelated = true;
      });
      _fetchRelatedBooks();
      _saveAndLoadRecentlyViewed();
    }
  }

  Future<void> _fetchRelatedBooks() async {
    try {
      final response = await sl<ApiClient>().getJson(
        '/books/${widget.book.id}/related',
      );
      if (response != null && response['data'] != null) {
        final List<dynamic> data = response['data'];
        final related = data.map((json) => BookModel.fromJson(json)).toList();
        if (mounted) {
          setState(() {
            _relatedBooks = related;
            _isLoadingRelated = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingRelated = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRelated = false;
        });
      }
    }
  }

  Future<void> _saveAndLoadRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list =
          prefs.getStringList('recently_viewed_books') ?? [];
      List<Map<String, dynamic>> parsedList = [];
      for (final s in list) {
        try {
          parsedList.add(jsonDecode(s) as Map<String, dynamic>);
        } catch (_) {}
      }
      parsedList.removeWhere((item) => item['id'] == widget.book.id);
      parsedList.insert(0, {
        'id': widget.book.id,
        'title': widget.book.title,
        'author': widget.book.author,
        'coverUrl': widget.book.coverUrl,
        'price': widget.book.price,
      });
      if (parsedList.length > 6) {
        parsedList = parsedList.sublist(0, 6);
      }
      final List<String> stringList = parsedList
          .map((item) => jsonEncode(item))
          .toList();
      await prefs.setStringList('recently_viewed_books', stringList);
    } catch (e) {
      debugPrint('Error saving recently viewed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1300),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: isMobile ? 16.0 : 24.0,
                      right: isMobile ? 16.0 : 24.0,
                      top: isMobile ? 16.0 : 24.0,
                      bottom: 48.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /*  Header Nav Breadcrumb */ Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {
                                    if (context.canPop()) {
                                      context.pop();
                                    } else {
                                      context.go('/browse');
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: DSColors.warmIvory,
                                          borderRadius: BorderRadius.circular(DSRadius.sm),
                                        ),
                                        child: const FaIcon(
                                          FontAwesomeIcons.arrowLeft,
                                          size: 13,
                                          color: DSColors.charcoal,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Back to Catalog',
                                        style: GoogleFonts.inter(
                                          color: DSColors.charcoal,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildNavArrow(FontAwesomeIcons.chevronLeft),
                                  const SizedBox(width: 8),
                                  _buildNavArrow(FontAwesomeIcons.chevronRight),
                                ],
                              ),
                            ],
                          ),
                        ),
                        /*  Layout */ LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 980) {
                              /*  3-column Professional Desktop layout: 340px, 1fr (500+px), 340px */
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 340,
                                    child: BookImagesSection(book: widget.book),
                                  ),
                                  const SizedBox(width: 36),
                                  Expanded(
                                    child: BookInfoSectionV2(book: widget.book),
                                  ),
                                  const SizedBox(width: 36),
                                  SizedBox(
                                    width: 340,
                                    child: BookActionCard(
                                      book: widget.book,
                                      onBorrow: (days) => _handleBorrow(context, days),
                                      onRent: (days) => _handleRent(context, days),
                                      onAddToCart: () => _handleAddToCart(context),
                                      onBuyNow: () => _handleBuyNow(context),
                                    ),
                                  ),
                                ],
                              );
                            } else if (constraints.maxWidth > 680) {
                              /*  2-column Tablet layout */
                              return Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 290,
                                        child: BookImagesSection(book: widget.book),
                                      ),
                                      const SizedBox(width: 28),
                                      Expanded(
                                        child: BookInfoSectionV2(book: widget.book),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),
                                  BookActionCard(
                                    book: widget.book,
                                    onBorrow: (days) => _handleBorrow(context, days),
                                    onRent: (days) => _handleRent(context, days),
                                    onAddToCart: () => _handleAddToCart(context),
                                    onBuyNow: () => _handleBuyNow(context),
                                  ),
                                ],
                              );
                            } else {
                              /*  Mobile stacked layout */
                              return Column(
                                children: [
                                  BookImagesSection(book: widget.book),
                                  const SizedBox(height: 28),
                                  BookInfoSectionV2(book: widget.book),
                                  const SizedBox(height: 28),
                                  BookActionCard(
                                    book: widget.book,
                                    onBorrow: (days) => _handleBorrow(context, days),
                                    onRent: (days) => _handleRent(context, days),
                                    onAddToCart: () => _handleAddToCart(context),
                                    onBuyNow: () => _handleBuyNow(context),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 72),
                        BookReviewsSection(book: widget.book),
                        /*  Related Books Section */ if (!_isLoadingRelated &&
                            _relatedBooks.isNotEmpty) ...[
                          const SizedBox(height: 72),
                          RelatedBooksSection(books: _relatedBooks),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const TactileFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavArrow(dynamic icon) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: DSColors.softBorder),
        ),
        alignment: Alignment.center,
        child: FaIcon(icon, size: 16, color: DSColors.charcoal),
      ),
    );
  }

  /*  --- Handlers --- */

  Future<void> _handleBorrow(BuildContext context, int days) async {
    if (!ApiService.isLoggedIn) {
      WelcomeToRentDialog.show(
        context,
        book: widget.book,
        action: 'borrow',
        rentalDays: days,
      );
      return;
    }
    context.push(
      '/buy-now-checkout',
      extra: {'book': widget.book, 'mode': 'borrow', 'rentalDays': days},
    );
  }

  Future<void> _handleRent(BuildContext context, int days) async {
    if (!ApiService.isLoggedIn) {
      WelcomeToRentDialog.show(
        context,
        book: widget.book,
        action: 'rent',
        rentalDays: days,
      );
      return;
    }
    context.push(
      '/buy-now-checkout',
      extra: {'book': widget.book, 'mode': 'rental', 'rentalDays': days},
    );
  }

  Future<void> _handleAddToCart(BuildContext context) async {
    if (!ApiService.isLoggedIn) {
      WelcomeToRentDialog.show(
        context,
        book: widget.book,
        action: 'cart',
        rentalDays: 14,
      );
      return;
    }
    final bookId = int.tryParse(widget.book.id) ?? 0;
    try {
      await ApiService.addToCart(bookId, isPurchase: true);
      if (!context.mounted) return;
      try {
        context.read<CartBloc>().add(CartStarted());
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${widget.book.title}" to cart'),
          backgroundColor: DSColors.deepForestGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: DSColors.antiqueGold,
            onPressed: () => context.push('/cart'),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: $e'),
          backgroundColor: DSColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleBuyNow(BuildContext context) async {
    if (!ApiService.isLoggedIn) {
      WelcomeToRentDialog.show(
        context,
        book: widget.book,
        action: 'buy',
      );
      return;
    }
    context.push(
      '/buy-now-checkout',
      extra: {'book': widget.book, 'mode': 'purchase'},
    );
  }
}
