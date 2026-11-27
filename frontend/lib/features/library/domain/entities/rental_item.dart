import 'package:equatable/equatable.dart';

class RentalItem extends Equatable {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final double progress; // 0.0 to 1.0
  final String dueLabel; // e.g., "Due in 2d" or "Oct 24"

  const RentalItem({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.progress,
    required this.dueLabel,
  });

  @override
  List<Object?> get props => [id, title, author, coverUrl, progress, dueLabel];
}
