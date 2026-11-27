import 'package:equatable/equatable.dart';
import 'issue_category.dart';
import 'issue_severity.dart';

class Issue extends Equatable {
  final IssueCategory? category;
  final IssueSeverity? severity;
  final String description;
  final List<String> attachments; // Paths to files

  const Issue({
    this.category,
    this.severity,
    this.description = '',
    this.attachments = const [],
  });

  Issue copyWith({
    IssueCategory? category,
    IssueSeverity? severity,
    String? description,
    List<String>? attachments,
  }) {
    return Issue(
      category: category ?? this.category,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  List<Object?> get props => [category, severity, description, attachments];
}
