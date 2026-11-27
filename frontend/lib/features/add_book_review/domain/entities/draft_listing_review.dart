import 'package:equatable/equatable.dart';
import 'physical_copy_review.dart';
import 'standard_check_item.dart';

class DraftListingReview extends Equatable {
  final String id;
  final String? coverUrl;
  final String? localImagePath;
  final String title;
  final String author;
  final String isbn13;
  final String editionLabel;
  final String summaryText;
  final List<PhysicalCopyReview> copies;
  final List<StandardCheckItem> standards;
  final double progressPercent;

  const DraftListingReview({
    required this.id,
    this.coverUrl,
    this.localImagePath,
    required this.title,
    required this.author,
    required this.isbn13,
    required this.editionLabel,
    required this.summaryText,
    required this.copies,
    required this.standards,
    required this.progressPercent,
  });

  @override
  List<Object?> get props => [
    id,
    coverUrl,
    localImagePath,
    title,
    author,
    isbn13,
    editionLabel,
    summaryText,
    copies,
    standards,
    progressPercent,
  ];
}
