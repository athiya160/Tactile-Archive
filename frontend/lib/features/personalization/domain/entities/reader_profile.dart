class ReaderProfile {
  final int? id;
  final int? userId;
  final List<String> genres;
  final List<String> favoriteAuthors;
  final String readingGoal;
  final int preferredDuration;
  final List<String> favoriteMoods;
  final String readingFrequency;

  const ReaderProfile({
    this.id,
    this.userId,
    this.genres = const [],
    this.favoriteAuthors = const [],
    this.readingGoal = 'Read 12 books this year',
    this.preferredDuration = 30,
    this.favoriteMoods = const [],
    this.readingFrequency = 'Daily',
  });
}
