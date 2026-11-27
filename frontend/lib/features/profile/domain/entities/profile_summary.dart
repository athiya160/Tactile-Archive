class ProfileSummary {
  final String name;
  final String level;
  final String avatarUrl;
  final int booksBorrowedCount;
  final int booksSharedCount;
  final bool isAdmin;

  const ProfileSummary({
    required this.name,
    required this.level,
    required this.avatarUrl,
    required this.booksBorrowedCount,
    required this.booksSharedCount,
    required this.isAdmin,
  });
}
