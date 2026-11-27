enum ListingType { forRent, forSale, donate }

class Book {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final List<String> categories;
  final double price;
  final double? originalPrice;
  final double? discountPercentage;
  final ListingType listingType;
  final double rating;
  final bool isStaffPick;
  final String description;
  final String? edition;
  final String? pages;
  final String publisher;
  final String language;
  final String isbn;
  final String category;
  final String? quote;
  final String? quoteAuthor;
  final bool isFavorite;
  final int stock;
  final String condition;

  // Amazon additions
  final int totalReviews;
  final String approvalStatus;
  final String conditionVerification;
  final String verificationNotes;
  final List<String> images;

  // Phase 16C.1 Provider, Availability & Multi-Modal Transaction Fields
  final Map<String, dynamic>? provider;
  final String? providerName;
  final String? providerCampus;
  final bool providerVerified;
  final double? providerRating;
  final bool isAvailable;
  final String availabilityStatus;
  final bool canBuy;
  final bool canRent;
  final bool canBorrow;
  final Map<String, dynamic>? rentalOptions;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.categories,
    required this.listingType,
    required this.rating,
    this.price = 0.0,
    this.originalPrice,
    this.discountPercentage,
    this.isStaffPick = false,
    this.isFavorite = false,
    this.stock = 1,
    this.condition = 'Good',
    this.description = '',
    this.edition,
    this.pages,
    this.publisher = '',
    this.language = '',
    this.isbn = '',
    this.category = 'Fiction',
    this.quote,
    this.quoteAuthor,
    this.totalReviews = 0,
    this.approvalStatus = 'approved',
    this.conditionVerification = 'verified',
    this.verificationNotes = '',
    this.images = const [],
    this.provider,
    this.providerName,
    this.providerCampus,
    this.providerVerified = false,
    this.providerRating,
    this.isAvailable = true,
    this.availabilityStatus = 'in_stock',
    this.canBuy = true,
    this.canRent = true,
    this.canBorrow = true,
    this.rentalOptions,
  });

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? coverUrl,
    List<String>? categories,
    double? price,
    double? originalPrice,
    double? discountPercentage,
    ListingType? listingType,
    double? rating,
    bool? isStaffPick,
    bool? isFavorite,
    String? description,
    String? edition,
    String? pages,
    String? publisher,
    String? language,
    String? isbn,
    String? category,
    String? quote,
    String? quoteAuthor,
    int? totalReviews,
    String? approvalStatus,
    String? conditionVerification,
    String? verificationNotes,
    List<String>? images,
    int? stock,
    String? condition,
    Map<String, dynamic>? provider,
    String? providerName,
    String? providerCampus,
    bool? providerVerified,
    double? providerRating,
    bool? isAvailable,
    String? availabilityStatus,
    bool? canBuy,
    bool? canRent,
    bool? canBorrow,
    Map<String, dynamic>? rentalOptions,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      categories: categories ?? this.categories,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      listingType: listingType ?? this.listingType,
      rating: rating ?? this.rating,
      isStaffPick: isStaffPick ?? this.isStaffPick,
      isFavorite: isFavorite ?? this.isFavorite,
      description: description ?? this.description,
      edition: edition ?? this.edition,
      pages: pages ?? this.pages,
      publisher: publisher ?? this.publisher,
      language: language ?? this.language,
      isbn: isbn ?? this.isbn,
      category: category ?? this.category,
      quote: quote ?? this.quote,
      quoteAuthor: quoteAuthor ?? this.quoteAuthor,
      totalReviews: totalReviews ?? this.totalReviews,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      conditionVerification:
          conditionVerification ?? this.conditionVerification,
      verificationNotes: verificationNotes ?? this.verificationNotes,
      images: images ?? this.images,
      stock: stock ?? this.stock,
      condition: condition ?? this.condition,
      provider: provider ?? this.provider,
      providerName: providerName ?? this.providerName,
      providerCampus: providerCampus ?? this.providerCampus,
      providerVerified: providerVerified ?? this.providerVerified,
      providerRating: providerRating ?? this.providerRating,
      isAvailable: isAvailable ?? this.isAvailable,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      canBuy: canBuy ?? this.canBuy,
      canRent: canRent ?? this.canRent,
      canBorrow: canBorrow ?? this.canBorrow,
      rentalOptions: rentalOptions ?? this.rentalOptions,
    );
  }

  bool get isFree => price == 0;
  bool get hasDiscount => discountPercentage != null && discountPercentage! > 0;
}
