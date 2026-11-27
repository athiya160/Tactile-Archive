import 'package:equatable/equatable.dart';
import '../../domain/entities/issue_category.dart';
import '../../domain/entities/issue_severity.dart';

abstract class ReportIssueEvent extends Equatable {
  const ReportIssueEvent();

  @override
  List<Object?> get props => [];
}

class ReportIssueStarted extends ReportIssueEvent {}

class ReportIssueCategoryChanged extends ReportIssueEvent {
  final IssueCategory category;
  const ReportIssueCategoryChanged(this.category);

  @override
  List<Object?> get props => [category];
}

class ReportIssueSeverityChanged extends ReportIssueEvent {
  final IssueSeverity severity;
  const ReportIssueSeverityChanged(this.severity);

  @override
  List<Object?> get props => [severity];
}

class ReportIssueDescriptionChanged extends ReportIssueEvent {
  final String description;
  const ReportIssueDescriptionChanged(this.description);

  @override
  List<Object?> get props => [description];
}

class ReportIssueAttachmentAdded extends ReportIssueEvent {
  final String path;
  const ReportIssueAttachmentAdded(this.path);

  @override
  List<Object?> get props => [path];
}

class ReportIssueAttachmentRemoved extends ReportIssueEvent {
  final String path;
  const ReportIssueAttachmentRemoved(this.path);

  @override
  List<Object?> get props => [path];
}

class ReportIssueSubmitted extends ReportIssueEvent {}
