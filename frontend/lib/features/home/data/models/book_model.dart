import '../../domain/entities/book.dart';
import '../../../../core/services/api_service.dart';

class BookModel extends Book {
  const BookModel({
    required super.id,
    required super.title,
    required super.author,
    required super.coverUrl,
    required super.categories,
    required super.listingType,
    required super.rating,
    super.price = 0.0,
    super.originalPrice,
    super.discountPercentage,
    super.isStaffPick = false,
    super.isFavorite = false,
    super.stock = 1,
    super.condition = 'Good',
    super.description = '',
    super.edition,
    super.pages,
    super.publisher = '',
    super.language = '',
    super.isbn = '',
    super.category = 'Fiction',
    super.quote,
    super.quoteAuthor,
    super.totalReviews = 0,
    super.approvalStatus = 'approved',
    super.conditionVerification = 'verified',
    super.verificationNotes = '',
    super.images = const [],
    super.provider,
    super.providerName,
    super.providerCampus,
    super.providerVerified = false,
    super.providerRating,
    super.isAvailable = true,
    super.availabilityStatus = 'in_stock',
    super.canBuy = true,
    super.canRent = true,
    super.canBorrow = true,
    super.rentalOptions,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    final parsedCategories = json['categories'] != null
        ? List<String>.from(json['categories'])
        : (json['category'] != null
              ? [json['category'].toString()]
              : <String>[]);

    final parsedImages = json['images'] != null
        ? (json['images'] as List)
              .map((i) => ApiService.resolveImageUrl(i.toString()))
              .toList()
        : <String>[];

    final providerMap = json['provider'] is Map<String, dynamic>
        ? json['provider'] as Map<String, dynamic>
        : null;

    final rentalOptionsMap = json['rental_options'] is Map<String, dynamic>
        ? json['rental_options'] as Map<String, dynamic>
        : null;

    return BookModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      coverUrl: ApiService.resolveImageUrl(
        json['coverUrl']?.toString() ?? json['image_url']?.toString() ?? '',
      ),
      categories: parsedCategories,
      listingType: _parseListingType(json['listingType']),
      rating: _parseDouble(json['rating']) ?? 0.0,
      price: _parseDouble(json['price']) ?? 0.0,
      originalPrice: _parseDouble(json['originalPrice']),
      discountPercentage: _parseDouble(json['discountPercentage']),
      isStaffPick: json['isStaffPick'] == true,
      isFavorite: json['isFavorite'] == true,
      stock: json['stock'] as int? ?? 1,
      condition: json['condition']?.toString() ?? 'Good',
      description: json['description']?.toString() ?? '',
      edition: json['edition']?.toString(),
      pages: json['pages']?.toString(),
      publisher: json['publisher']?.toString() ?? '',
      language: json['language']?.toString() ?? '',
      isbn: json['isbn']?.toString() ?? '',
      category:
          json['category']?.toString() ??
          (parsedCategories.isNotEmpty ? parsedCategories.first : 'Fiction'),
      quote: json['quote']?.toString(),
      quoteAuthor: json['quoteAuthor']?.toString(),
      totalReviews: json['totalReviews'] as int? ?? 0,
      approvalStatus: json['approval_status']?.toString() ?? 'approved',
      conditionVerification:
          json['condition_verification']?.toString() ?? 'verified',
      verificationNotes: json['verification_notes']?.toString() ?? '',
      images: parsedImages,
      provider: providerMap,
      providerName: json['provider_name']?.toString() ??
          (providerMap != null ? providerMap['name']?.toString() : null),
      providerCampus: json['provider_campus']?.toString() ??
          (providerMap != null ? providerMap['campus']?.toString() : null),
      providerVerified: json['provider_verified'] == true ||
          (providerMap != null && providerMap['is_verified'] == true),
      providerRating: _parseDouble(json['provider_rating'] ??
          (providerMap != null ? providerMap['rating'] : null)),
      isAvailable: json['is_available'] != null
          ? json['is_available'] == true
          : ((json['stock'] as int? ?? 1) > 0),
      availabilityStatus: json['availability_status']?.toString() ?? 'in_stock',
      canBuy: json['can_buy'] != null ? json['can_buy'] == true : true,
      canRent: json['can_rent'] != null ? json['can_rent'] == true : true,
      canBorrow: json['can_borrow'] != null ? json['can_borrow'] == true : true,
      rentalOptions: rentalOptionsMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'categories': categories,
      'listingType': _listingTypeToString(listingType),
      'rating': rating,
      'price': price,
      if (originalPrice != null) 'originalPrice': originalPrice,
      if (discountPercentage != null) 'discountPercentage': discountPercentage,
      'isStaffPick': isStaffPick,
      'isFavorite': isFavorite,
      'stock': stock,
      'condition': condition,
      'description': description,
      if (edition != null) 'edition': edition,
      if (pages != null) 'pages': pages,
      'publisher': publisher,
      'language': language,
      'isbn': isbn,
      'category': category,
      if (quote != null) 'quote': quote,
      if (quoteAuthor != null) 'quoteAuthor': quoteAuthor,
      'totalReviews': totalReviews,
      'approval_status': approvalStatus,
      'condition_verification': conditionVerification,
      'verification_notes': verificationNotes,
      'images': images,
      if (provider != null) 'provider': provider,
      if (providerName != null) 'provider_name': providerName,
      if (providerCampus != null) 'provider_campus': providerCampus,
      'provider_verified': providerVerified,
      if (providerRating != null) 'provider_rating': providerRating,
      'is_available': isAvailable,
      'availability_status': availabilityStatus,
      'can_buy': canBuy,
      'can_rent': canRent,
      'can_borrow': canBorrow,
      if (rentalOptions != null) 'rental_options': rentalOptions,
    };
  }

  static ListingType _parseListingType(dynamic raw) {
    final value = raw?.toString().toLowerCase();
    switch (value) {
      case 'forrent':
      case 'for_rent':
      case 'for rent':
        return ListingType.forRent;
      case 'forsale':
      case 'for_sale':
      case 'for sale':
        return ListingType.forSale;
      case 'donate':
      case 'donation':
        return ListingType.donate;
      default:
        return ListingType.forSale;
    }
  }

  static String _listingTypeToString(ListingType type) {
    switch (type) {
      case ListingType.forRent:
        return 'forRent';
      case ListingType.forSale:
        return 'forSale';
      case ListingType.donate:
        return 'donate';
    }
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
