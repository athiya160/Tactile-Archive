import 'package:equatable/equatable.dart';

class Faq extends Equatable {
  final String question;
  final String answer;

  const Faq({required this.question, required this.answer});

  @override
  List<Object?> get props => [question, answer];
}
