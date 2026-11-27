import '../entities/issue.dart';

abstract class IssueRepository {
  Future<void> submitIssue(Issue issue);
}
