import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/activity_item.dart';
import '../repositories/activity_repository.dart';

class GetActivityFeed implements UseCase<List<ActivityItem>, NoParams> {
  final ActivityRepository repository;

  GetActivityFeed(this.repository);

  @override
  Future<Result<List<ActivityItem>>> call(NoParams params) {
    return repository.getActivityFeed();
  }
}
