class BookshelfItemModel {
  final int id;
  final int userId;
  final int? bookId;
  final String title;
  final String author;
  final String? coverUrl;
  final String category;
  final double progress;
  final int currentPage;
  final int totalPages;
  final String status;
  final String format;
  final int? daysLeft;
  final String? genre;
  final String? personalNotes;
  final double? rating;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BookshelfItemModel({
    required this.id,
    required this.userId,
    this.bookId,
    required this.title,
    required this.author,
    this.coverUrl,
    this.category = 'want_to_read',
    this.progress = 0.0,
    this.currentPage = 0,
    this.totalPages = 300,
    this.status = 'Personal Library',
    this.format = 'Paperback',
    this.daysLeft,
    this.genre,
    this.personalNotes,
    this.rating,
    this.startedAt,
    this.finishedAt,
    this.createdAt,
    this.updatedAt,
  });

  int get percentRead => (progress * 100).round();
  bool get isFinished => category == 'completed' || progress >= 1.0;
  int get pagesRemaining => (totalPages - currentPage).clamp(0, totalPages);

  factory BookshelfItemModel.fromJson(Map<String, dynamic> json) {
    return BookshelfItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      bookId: json['book_id'] != null ? int.tryParse(json['book_id'].toString()) : null,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      coverUrl: json['cover_url'] as String?,
      category: json['category'] as String? ?? 'want_to_read',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      currentPage: (json['current_page'] as num?)?.toInt() ?? 0,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 300,
      status: json['status'] as String? ?? 'Personal Library',
      format: json['format'] as String? ?? 'Paperback',
      daysLeft: (json['days_left'] as num?)?.toInt(),
      genre: json['genre'] as String?,
      personalNotes: json['personal_notes'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      startedAt: json['started_at'] != null ? DateTime.tryParse(json['started_at'].toString()) : null,
      finishedAt: json['finished_at'] != null ? DateTime.tryParse(json['finished_at'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId,
      'title': title,
      'author': author,
      'cover_url': coverUrl,
      'category': category,
      'progress': progress,
      'current_page': currentPage,
      'total_pages': totalPages,
      'status': status,
      'format': format,
      'days_left': daysLeft,
      'genre': genre,
      'personal_notes': personalNotes,
      'rating': rating,
      if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
      if (finishedAt != null) 'finished_at': finishedAt!.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  BookshelfItemModel copyWith({
    int? id,
    int? userId,
    int? bookId,
    String? title,
    String? author,
    String? coverUrl,
    String? category,
    double? progress,
    int? currentPage,
    int? totalPages,
    String? status,
    String? format,
    int? daysLeft,
    String? genre,
    String? personalNotes,
    double? rating,
    DateTime? startedAt,
    DateTime? finishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookshelfItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      category: category ?? this.category,
      progress: progress ?? this.progress,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      status: status ?? this.status,
      format: format ?? this.format,
      daysLeft: daysLeft ?? this.daysLeft,
      genre: genre ?? this.genre,
      personalNotes: personalNotes ?? this.personalNotes,
      rating: rating ?? this.rating,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
