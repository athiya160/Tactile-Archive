import '../../domain/entities/issue.dart';
import '../../domain/repositories/issue_repository.dart';

class MockIssueRepository implements IssueRepository {
  @override
  Future<void> submitIssue(Issue issue) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // In a mock implementation, we just succeed.
    // We could add logic to fail if description is 'fail' for testing error states.
    if (issue.description.toLowerCase() == 'fail') {
      throw Exception('Failed to submit issue. Please try again.');
    }
  }
}
