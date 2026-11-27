import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart';
import '../entities/issue.dart';
import '../repositories/issue_repository.dart';

class SubmitReport implements UseCase<void, Issue> {
  final IssueRepository repository;

  SubmitReport(this.repository);

  @override
  Future<Result<void>> call(Issue issue) async {
    // Validate issue input
    if (issue.category == null) {
      return Result.failure(
        const ValidationFailure('Issue category must be selected'),
      );
    }
    if (issue.description.isEmpty) {
      return Result.failure(
        const ValidationFailure('Issue description cannot be empty'),
      );
    }

    try {
      await repository.submitIssue(issue);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        ServerFailure('Failed to submit issue: ${e.toString()}'),
      );
    }
  }
}
