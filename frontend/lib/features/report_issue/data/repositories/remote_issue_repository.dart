import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/issue.dart';
import '../../domain/repositories/issue_repository.dart';

class RemoteIssueRepository implements IssueRepository {
  final ApiClient apiClient;

  RemoteIssueRepository(this.apiClient);

  @override
  Future<Result<void>> submitIssue(Issue issue) async {
    try {
      await apiClient.postJson(
        '/support/issues',
        body: {
          'category': issue.category?.name,
          'severity': issue.severity?.name,
          'description': issue.description,
          'attachments': issue.attachments,
        },
      );
      return Result.success(null);
    } on Failure catch (error) {
      return Result.failure(error);
    } catch (error) {
      return Result.failure(ServerFailure(error.toString()));
    }
  }
}
