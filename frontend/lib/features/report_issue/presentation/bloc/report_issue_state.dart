import 'package:equatable/equatable.dart';
import '../../domain/entities/issue.dart';

enum ReportIssueStatus { initial, loading, success, failure }

class ReportIssueState extends Equatable {
  final Issue issue;
  final ReportIssueStatus status;
  final String? errorMessage;

  const ReportIssueState({
    this.issue = const Issue(),
    this.status = ReportIssueStatus.initial,
    this.errorMessage,
  });

  ReportIssueState copyWith({
    Issue? issue,
    ReportIssueStatus? status,
    String? errorMessage,
  }) {
    return ReportIssueState(
      issue: issue ?? this.issue,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [issue, status, errorMessage];
}
