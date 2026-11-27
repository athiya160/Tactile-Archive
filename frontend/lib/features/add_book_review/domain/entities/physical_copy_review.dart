import 'package:equatable/equatable.dart';

class PhysicalCopyReview extends Equatable {
  final String id;
  final String title;
  final String subtext;
  final List<String> chips;
  final String? price;
  final String icon;

  const PhysicalCopyReview({
    required this.id,
    required this.title,
    required this.subtext,
    required this.chips,
    this.price,
    this.icon = 'default',
  });

  @override
  List<Object?> get props => [id, title, subtext, chips, price, icon];
}
