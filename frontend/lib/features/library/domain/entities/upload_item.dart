import 'package:equatable/equatable.dart';

enum UploadStatus { active, pending }

class UploadItem extends Equatable {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final UploadStatus status;

  const UploadItem({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    required this.status,
  });

  @override
  List<Object?> get props => [id, title, author, coverUrl, status];
}
