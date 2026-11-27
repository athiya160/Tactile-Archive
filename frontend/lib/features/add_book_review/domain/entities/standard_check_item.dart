import 'package:equatable/equatable.dart';

class StandardCheckItem extends Equatable {
  final String id;
  final String text;
  final bool isChecked;

  const StandardCheckItem({
    required this.id,
    required this.text,
    this.isChecked = true,
  });

  @override
  List<Object?> get props => [id, text, isChecked];
}
