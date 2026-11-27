class ReadingGoalModel {
  final int id;
  final int userId;
  final int year;
  final int targetBooks;
  final int completedBooks;
  final int targetPages;
  final int pagesRead;
  final int dailyReadingGoalMinutes;
  final int streakDays;
  final String? lastReadDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ReadingGoalModel({
    required this.id,
    required this.userId,
    required this.year,
    this.targetBooks = 12,
    this.completedBooks = 0,
    this.targetPages = 3000,
    this.pagesRead = 0,
    this.dailyReadingGoalMinutes = 30,
    this.streakDays = 0,
    this.lastReadDate,
    this.createdAt,
    this.updatedAt,
  });

  double get bookProgress => targetBooks > 0 ? (completedBooks / targetBooks).clamp(0.0, 1.0) : 0.0;
  int get bookProgressPercent => (bookProgress * 100).round();
  int get booksRemaining => (targetBooks - completedBooks).clamp(0, targetBooks);

  double get pageProgress => targetPages > 0 ? (pagesRead / targetPages).clamp(0.0, 1.0) : 0.0;
  int get pageProgressPercent => (pageProgress * 100).round();
  int get pagesRemaining => (targetPages - pagesRead).clamp(0, targetPages);

  factory ReadingGoalModel.fromJson(Map<String, dynamic> json) {
    return ReadingGoalModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      targetBooks: (json['target_books'] as num?)?.toInt() ?? 12,
      completedBooks: (json['completed_books'] as num?)?.toInt() ?? 0,
      targetPages: (json['target_pages'] as num?)?.toInt() ?? 3000,
      pagesRead: (json['pages_read'] as num?)?.toInt() ?? 0,
      dailyReadingGoalMinutes: (json['daily_reading_goal_minutes'] as num?)?.toInt() ?? 30,
      streakDays: (json['streak_days'] as num?)?.toInt() ?? 0,
      lastReadDate: json['last_read_date'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'year': year,
      'target_books': targetBooks,
      'completed_books': completedBooks,
      'target_pages': targetPages,
      'pages_read': pagesRead,
      'daily_reading_goal_minutes': dailyReadingGoalMinutes,
      'streak_days': streakDays,
      'last_read_date': lastReadDate,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  ReadingGoalModel copyWith({
    int? id,
    int? userId,
    int? year,
    int? targetBooks,
    int? completedBooks,
    int? targetPages,
    int? pagesRead,
    int? dailyReadingGoalMinutes,
    int? streakDays,
    String? lastReadDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReadingGoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      year: year ?? this.year,
      targetBooks: targetBooks ?? this.targetBooks,
      completedBooks: completedBooks ?? this.completedBooks,
      targetPages: targetPages ?? this.targetPages,
      pagesRead: pagesRead ?? this.pagesRead,
      dailyReadingGoalMinutes: dailyReadingGoalMinutes ?? this.dailyReadingGoalMinutes,
      streakDays: streakDays ?? this.streakDays,
      lastReadDate: lastReadDate ?? this.lastReadDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
