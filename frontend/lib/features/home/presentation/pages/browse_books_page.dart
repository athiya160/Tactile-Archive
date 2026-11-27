import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/tactile_footer.dart';

/// Phase 16B.4: Explore, Search, Filters & Recommendations Redesign
/// Luxury editorial book discovery experience for The Tactile Archive.
class BrowseBooksPage extends StatefulWidget {
  final String? initialCategory;
  final String? initialSearchQuery;
  final String? from;

  const BrowseBooksPage({
    super.key,
    this.initialCategory,
    this.initialSearchQuery,
    this.from,
  });

  @override
  State<BrowseBooksPage> createState() => _BrowseBooksPageState();
}

class _BrowseBooksPageState extends State<BrowseBooksPage> {
  // Search & Filter State
  late final TextEditingController _searchController;
  Timer? _debounceTimer;

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedListingType = 'All';
  String _selectedCondition = 'All';
  String _selectedPriceRange = 'All';
  String _sortBy = 'relevance';

  // Catalog Pagination & Data
  int _currentPage = 1;
  static const int _pageSize = 20;
  int _totalCount = 0;
  bool _hasMore = false;
  bool _isLoadingCatalog = false;
  bool _isLoadingMore = false;
  String? _catalogError;
  List<Map<String, dynamic>> _books = [];

  // Recommendations Data
  bool _isLoadingRecommendations = false;
  List<Map<String, dynamic>> _recommendations = [];

  // Favorites Cache
  final Set<int> _favoriteBookIds = {};

  // Preset Filters
  static const List<String> _categories = [
    'All',
    'Academic & Textbooks',
    'Tech & Programming',
    'Fiction',
    'Science & Nature',
    'Business & Finance',
    'History & Biography',
    'Self Development',
    'Rare Finds',
  ];

  static const List<Map<String, String>> _listingTypes = [
    {'label': 'All Types', 'value': 'All'},
    {'label': 'Buy', 'value': 'forSale'},
    {'label': 'Rent', 'value': 'forRent'},
    {'label': 'Borrow', 'value': 'donate'},
  ];

  static const List<String> _conditions = [
    'All',
    'New',
    'Like New',
    'Good',
    'Fair',
  ];

  static const List<Map<String, dynamic>> _pricePresets = [
    {'label': 'Any Price', 'value': 'All', 'min': null, 'max': null},
    {'label': 'Under ₹150', 'value': 'under150', 'min': 0.0, 'max': 150.0},
    {'label': '₹150 – ₹400', 'value': '150-400', 'min': 150.0, 'max': 400.0},
    {'label': '₹400+', 'value': '400plus', 'min': 400.0, 'max': null},
  ];

  static const List<Map<String, String>> _sortOptions = [
    {'label': 'Curated Relevance', 'value': 'relevance'},
    {'label': 'Price: Low to High', 'value': 'price_asc'},
    {'label': 'Price: High to Low', 'value': 'price_desc'},
    {'label': 'Newest Additions', 'value': 'newest'},
    {'label': 'Highest Rated', 'value': 'rating'},
  ];

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialSearchQuery?.trim() ?? '';
    _searchController = TextEditingController(text: _searchQuery);

    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _selectedCategory = widget.initialCategory!;
    }

    _loadInitialData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    _loadFavorites();
    _loadRecommendations();
    _fetchBooks(reset: true);
  }

  Future<void> _loadFavorites() async {
    try {
      if (ApiService.isLoggedIn) {
        final favs = await ApiService.getFavorites();
        if (mounted) {
          setState(() {
            _favoriteBookIds.clear();
            for (final f in favs) {
              if (f is Map && f['id'] != null) {
                final id = int.tryParse(f['id'].toString());
                if (id != null) _favoriteBookIds.add(id);
              }
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadRecommendations() async {
    if (!mounted) return;
    setState(() => _isLoadingRecommendations = true);
    try {
      final recs = await ApiService.getPersonalizedRecommendations(limit: 8);
      if (mounted) {
        setState(() {
          _recommendations = recs;
          _isLoadingRecommendations = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingRecommendations = false);
    }
  }

  (double?, double?) _getActivePriceRange() {
    for (final p in _pricePresets) {
      if (p['value'] == _selectedPriceRange) {
        return (p['min'] as double?, p['max'] as double?);
      }
    }
    return (null, null);
  }

  Future<void> _fetchBooks({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _isLoadingCatalog = true;
        _catalogError = null;
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    }

    final (minP, maxP) = _getActivePriceRange();

    try {
      final res = await ApiService.getBooks(
        page: _currentPage,
        limit: _pageSize,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        category: _selectedCategory != 'All' ? _selectedCategory : null,
        minPrice: minP,
        maxPrice: maxP,
        listingType: _selectedListingType != 'All' ? _selectedListingType : null,
        condition: _selectedCondition != 'All' ? _selectedCondition : null,
        sortBy: _sortBy,
      );

      final rawData = res['data'];
      final List<Map<String, dynamic>> newBooks = [];
      if (rawData is List) {
        for (final item in rawData) {
          if (item is Map) {
            newBooks.add(Map<String, dynamic>.from(item));
          }
        }
      }

      final total = res['total'] as int? ?? newBooks.length;
      final hasMore = res['has_more'] as bool? ?? false;

      if (mounted) {
        setState(() {
          if (reset) {
            _books = newBooks;
          } else {
            _books.addAll(newBooks);
          }
          _totalCount = total;
          _hasMore = hasMore;
          _isLoadingCatalog = false;
          _isLoadingMore = false;
          _catalogError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCatalog = false;
          _isLoadingMore = false;
          _catalogError = 'Unable to load catalog volumes. Please check your connection.';
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _searchQuery = query.trim();
        });
        _fetchBooks(reset: true);
      }
    });
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
    });
    _fetchBooks(reset: true);
  }

  void _onListingTypeSelected(String type) {
    if (_selectedListingType == type) return;
    setState(() {
      _selectedListingType = type;
    });
    _fetchBooks(reset: true);
  }

  void _onConditionSelected(String cond) {
    if (_selectedCondition == cond) return;
    setState(() {
      _selectedCondition = cond;
    });
    _fetchBooks(reset: true);
  }

  void _onPriceRangeSelected(String range) {
    if (_selectedPriceRange == range) return;
    setState(() {
      _selectedPriceRange = range;
    });
    _fetchBooks(reset: true);
  }

  void _onSortChanged(String? newSort) {
    if (newSort == null || newSort == _sortBy) return;
    setState(() {
      _sortBy = newSort;
    });
    _fetchBooks(reset: true);
  }

  void _resetAllFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'All';
      _selectedListingType = 'All';
      _selectedCondition = 'All';
      _selectedPriceRange = 'All';
      _sortBy = 'relevance';
    });
    _fetchBooks(reset: true);
  }

  bool get _hasActiveFilters {
    return _searchQuery.isNotEmpty ||
        _selectedCategory != 'All' ||
        _selectedListingType != 'All' ||
        _selectedCondition != 'All' ||
        _selectedPriceRange != 'All' ||
        _sortBy != 'relevance';
  }

  Future<void> _toggleFavorite(int bookId) async {
    if (!ApiService.isLoggedIn) {
      context.go('/login');
      return;
    }

    final isFav = _favoriteBookIds.contains(bookId);
    setState(() {
      if (isFav) {
        _favoriteBookIds.remove(bookId);
      } else {
        _favoriteBookIds.add(bookId);
      }
    });

    try {
      final res = await ApiService.toggleFavorite(bookId);
      final serverFav = res['isFavorite'] as bool? ?? !isFav;
      if (mounted) {
        setState(() {
          if (serverFav) {
            _favoriteBookIds.add(bookId);
          } else {
            _favoriteBookIds.remove(bookId);
          }
        });
      }
    } catch (_) {
      // Revert optimistic update on error
      if (mounted) {
        setState(() {
          if (isFav) {
            _favoriteBookIds.add(bookId);
          } else {
            _favoriteBookIds.remove(bookId);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.paperWhite,
      body: CustomScrollView(
        slivers: [
          // 1. Editorial Explore Header & Search Bar
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),

          // 2. Personalized AI Recommendations Carousel
          if (_recommendations.isNotEmpty || _isLoadingRecommendations)
            SliverToBoxAdapter(
              child: _buildRecommendationsSection(),
            ),

          // 3. Multi-dimensional Filter Bar & Sort Controls
          SliverToBoxAdapter(
            child: _buildFilterSection(),
          ),

          // 4. Catalog Results Grid / Skeleton / Empty / Error
          _buildCatalogContent(),

          // 5. Load More Pagination Button
          if (_hasMore && !_isLoadingCatalog && _books.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildLoadMoreButton(),
            ),

          // 6. Tactile Archival Footer
          const SliverToBoxAdapter(
            child: TactileFooter(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      color: DSColors.warmIvory,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 24 : 36,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 10, height: 2, color: DSColors.secondaryGreen),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'THE TACTILE ARCHIVE • DISCOVERY',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: DSColors.secondaryGreen,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Explore The Library',
                style: GoogleFonts.playfairDisplay(
                  fontSize: isMobile ? 28 : 40,
                  fontWeight: FontWeight.w700,
                  color: DSColors.deepForestGreen,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Discover verified textbooks, rare first editions, and peer volumes across academic hubs.',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 13 : 15,
                  color: DSColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Search Bar with 350ms Debounce
              DSSearchBar(
                controller: _searchController,
                hintText: 'Search by title, author, ISBN, or topic...',
                onChanged: _onSearchChanged,
                onClear: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                onScanTap: () => _openIsbnScannerDialog(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 24,
      ),
      color: DSColors.paperWhite,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(
                eyebrow: ApiService.isLoggedIn ? 'TAILORED FOR YOU' : 'CURATED HIGHLIGHTS',
                title: ApiService.isLoggedIn ? 'Recommended Volumes' : 'Editor’s Archival Selection',
                subtitle: 'Ranked candidate titles based on your study subjects and reading preferences.',
              ),
              const SizedBox(height: 16),

              if (_isLoadingRecommendations)
                SizedBox(
                  height: 390,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (_, __) => const SizedBox(
                      width: 190,
                      child: DSSkeletonBookCard(),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 390,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recommendations.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final book = _recommendations[index];
                      final id = int.tryParse(book['id']?.toString() ?? '0') ?? 0;
                      final isFav = _favoriteBookIds.contains(id);
                      final price = double.tryParse(book['price']?.toString() ?? '0.0') ?? 0.0;
                      final rating = double.tryParse(book['rating']?.toString() ?? '4.8') ?? 4.8;

                      return EditorialBookCard(
                        width: 190,
                        imageHeight: 175,
                        title: book['title'] ?? 'Archival Volume',
                        author: book['author'] ?? 'Unknown Author',
                        price: price,
                        imageUrl: book['image_url'] ?? book['cover_url'] ?? book['image'],
                        condition: book['condition'] ?? 'Good',
                        availability: price == 0 ? 'Borrow' : (price < 5 ? 'Rent' : 'Buy'),
                        providerName: book['category'] ?? 'Tactile Archive',
                        rating: rating,
                        isFavorite: isFav,
                        onTap: () => context.go('/book/$id'),
                        onFavoriteToggle: () => _toggleFavorite(id),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      decoration: const BoxDecoration(
        color: DSColors.warmIvory,
        border: Border(
          top: BorderSide(color: DSColors.softBorder),
          bottom: BorderSide(color: DSColors.softBorder),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 18,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: DSChip(
                        label: cat,
                        isSelected: isSelected,
                        onSelected: (_) => _onCategorySelected(cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Secondary Filters: Listing Type, Condition, Price, Sort
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Listing Type (Buy / Rent / Borrow)
                  ..._listingTypes.map((type) {
                    final isSelected = _selectedListingType == type['value'];
                    return DSChip(
                      label: type['label']!,
                      isSelected: isSelected,
                      onSelected: (_) => _onListingTypeSelected(type['value']!),
                    );
                  }),

                  const SizedBox(width: 8),

                  // Condition Filter Dropdown / Menu
                  PopupMenuButton<String>(
                    tooltip: 'Filter by Condition',
                    initialValue: _selectedCondition,
                    onSelected: _onConditionSelected,
                    color: DSColors.paperWhite,
                    itemBuilder: (context) => _conditions.map((cond) {
                      return PopupMenuItem<String>(
                        value: cond,
                        child: Text(
                          cond == 'All' ? 'All Conditions' : cond,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: _selectedCondition == cond ? FontWeight.w700 : FontWeight.w400,
                            color: _selectedCondition == cond ? DSColors.deepForestGreen : DSColors.charcoal,
                          ),
                        ),
                      );
                    }).toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _selectedCondition != 'All' ? DSColors.deepForestGreen : DSColors.paperWhite,
                        borderRadius: BorderRadius.circular(DSRadius.sm),
                        border: Border.all(
                          color: _selectedCondition != 'All' ? DSColors.deepForestGreen : DSColors.softBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 14,
                            color: _selectedCondition != 'All' ? Colors.white : DSColors.charcoal,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _selectedCondition == 'All' ? 'Condition' : _selectedCondition,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _selectedCondition != 'All' ? Colors.white : DSColors.charcoal,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color: _selectedCondition != 'All' ? Colors.white : DSColors.charcoal,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Price Presets Dropdown
                  PopupMenuButton<String>(
                    tooltip: 'Filter by Price Range',
                    initialValue: _selectedPriceRange,
                    onSelected: _onPriceRangeSelected,
                    color: DSColors.paperWhite,
                    itemBuilder: (context) => _pricePresets.map((p) {
                      return PopupMenuItem<String>(
                        value: p['value'] as String,
                        child: Text(
                          p['label'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: _selectedPriceRange == p['value'] ? FontWeight.w700 : FontWeight.w400,
                            color: _selectedPriceRange == p['value'] ? DSColors.deepForestGreen : DSColors.charcoal,
                          ),
                        ),
                      );
                    }).toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _selectedPriceRange != 'All' ? DSColors.deepForestGreen : DSColors.paperWhite,
                        borderRadius: BorderRadius.circular(DSRadius.sm),
                        border: Border.all(
                          color: _selectedPriceRange != 'All' ? DSColors.deepForestGreen : DSColors.softBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.currency_rupee_rounded,
                            size: 13,
                            color: _selectedPriceRange != 'All' ? Colors.white : DSColors.charcoal,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _selectedPriceRange == 'All' ? 'Price' : _getPriceLabel(_selectedPriceRange),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _selectedPriceRange != 'All' ? Colors.white : DSColors.charcoal,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color: _selectedPriceRange != 'All' ? Colors.white : DSColors.charcoal,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Sort Options Dropdown
                  PopupMenuButton<String>(
                    tooltip: 'Sort Catalog',
                    initialValue: _sortBy,
                    onSelected: _onSortChanged,
                    color: DSColors.paperWhite,
                    itemBuilder: (context) => _sortOptions.map((opt) {
                      return PopupMenuItem<String>(
                        value: opt['value']!,
                        child: Text(
                          opt['label']!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: _sortBy == opt['value'] ? FontWeight.w700 : FontWeight.w400,
                            color: _sortBy == opt['value'] ? DSColors.deepForestGreen : DSColors.charcoal,
                          ),
                        ),
                      );
                    }).toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: DSColors.paperWhite,
                        borderRadius: BorderRadius.circular(DSRadius.sm),
                        border: Border.all(color: DSColors.softBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sort_rounded, size: 14, color: DSColors.deepForestGreen),
                          const SizedBox(width: 6),
                          Text(
                            _getSortLabel(_sortBy),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: DSColors.charcoal,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, size: 16, color: DSColors.charcoal),
                        ],
                      ),
                    ),
                  ),

                  // Reset All Filters Button
                  if (_hasActiveFilters)
                    TextButton.icon(
                      onPressed: _resetAllFilters,
                      icon: const Icon(Icons.restart_alt_rounded, size: 15, color: DSColors.mutedTerracotta),
                      label: Text(
                        'Reset Filters',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: DSColors.mutedTerracotta,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Active Results Counter
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isLoadingCatalog
                          ? 'Cataloging library volumes...'
                          : 'Showing ${_books.length} of $_totalCount available volumes',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: DSColors.textMuted,
                      ),
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

  Widget _buildCatalogContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    // Loading Skeletons State
    if (_isLoadingCatalog) {
      return SliverPadding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 32,
          vertical: 24,
        ),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: _buildResponsiveGrid(
                itemCount: 8,
                itemBuilder: (context, index) => const DSSkeletonBookCard(),
              ),
            ),
          ),
        ),
      );
    }

    // Error State
    if (_catalogError != null) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: DSErrorState(
              title: 'Archival Catalog Unavailable',
              message: _catalogError!,
              retryLabel: 'Retry Search',
              onRetry: () => _fetchBooks(reset: true),
            ),
          ),
        ),
      );
    }

    // Empty Results State
    if (_books.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: DSEmptyState(
              icon: Icons.search_off_rounded,
              title: 'No Matching Volumes Found',
              description: 'We couldn’t find any catalog volumes matching your current search terms or filter selection.',
              actionLabel: 'Clear All Filters',
              onAction: _resetAllFilters,
            ),
          ),
        ),
      );
    }

    // Books Grid
    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 24,
      ),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: _buildResponsiveGrid(
              itemCount: _books.length,
              itemBuilder: (context, index) {
                final b = _books[index];
                final id = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
                final price = double.tryParse(b['price']?.toString() ?? '0.0') ?? 0.0;
                final rating = double.tryParse(b['rating']?.toString() ?? '0.0') ?? 0.0;
                final isFav = _favoriteBookIds.contains(id);

                String availability = 'Buy';
                final listingType = b['listingType']?.toString().toLowerCase() ?? '';
                if (listingType == 'forrent' || (price > 0 && price < 5.0)) {
                  availability = 'Rent';
                } else if (listingType == 'donate' || price == 0) {
                  availability = 'Borrow';
                }

                return EditorialBookCard(
                  width: isMobile ? 165 : 190,
                  imageHeight: isMobile ? 150 : 175,
                  title: b['title'] ?? 'Archival Volume',
                  author: b['author'] ?? 'Unknown Author',
                  price: price,
                  imageUrl: b['cover_url'] ?? b['image_url'] ?? b['coverUrl'],
                  condition: b['condition'] ?? 'Good',
                  availability: availability,
                  providerName: b['publisher'] ?? b['category'] ?? 'The Tactile Archive',
                  rating: rating > 0 ? rating : null,
                  reviewCount: b['totalReviews'] as int? ?? 0,
                  isFavorite: isFav,
                  onTap: () => context.go('/book/$id'),
                  onFavoriteToggle: () => _toggleFavorite(id),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 2;
        if (width >= 1080) {
          crossAxisCount = 5;
        } else if (width >= 860) {
          crossAxisCount = 4;
        } else if (width >= 620) {
          crossAxisCount = 3;
        }

        final double spacing = width < 600 ? 12 : 16;
        final double itemWidth = (width - (spacing * (crossAxisCount - 1))) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(itemCount, (index) {
            return SizedBox(
              width: itemWidth,
              child: itemBuilder(context, index),
            );
          }),
        );
      },
    );
  }

  Widget _buildLoadMoreButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: _isLoadingMore
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(DSColors.deepForestGreen),
                ),
              )
            : DSButton(
                text: 'Load More Volumes',
                variant: DSButtonVariant.secondary,
                icon: Icons.expand_more_rounded,
                onPressed: () {
                  _currentPage += 1;
                  _fetchBooks(reset: false);
                },
              ),
      ),
    );
  }

  void _openIsbnScannerDialog() {
    final isbnCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: DSColors.paperWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DSRadius.card),
            side: const BorderSide(color: DSColors.softBorder),
          ),
          title: Text(
            'Search by ISBN',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: DSColors.deepForestGreen,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter a 10-digit or 13-digit ISBN barcode number to search directly across academic and archival holdings.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: DSColors.textLight,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              DSTextField(
                labelText: 'ISBN Code',
                hintText: 'e.g. 978-0132350884',
                controller: isbnCtrl,
                prefixIcon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          actions: [
            DSButton.secondary(
              text: 'Cancel',
              height: 48,
              onPressed: () => Navigator.pop(context),
            ),
            DSButton.primary(
              text: 'Search Volume',
              height: 48,
              onPressed: () {
                final isbn = isbnCtrl.text.trim();
                if (isbn.isNotEmpty) {
                  Navigator.pop(context);
                  _searchController.text = isbn;
                  _onSearchChanged(isbn);
                }
              },
            ),
          ],
        );
      },
    );
  }

  String _getPriceLabel(String val) {
    for (final p in _pricePresets) {
      if (p['value'] == val) return p['label'] as String;
    }
    return 'Price';
  }

  String _getSortLabel(String val) {
    for (final s in _sortOptions) {
      if (s['value'] == val) return s['label']!;
    }
    return 'Relevance';
  }
}
