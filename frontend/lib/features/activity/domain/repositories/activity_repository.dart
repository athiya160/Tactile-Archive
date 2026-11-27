import '../../../../core/utils/result.dart';
import '../entities/activity_item.dart';

abstract class ActivityRepository {
  Future<Result<List<ActivityItem>>> getActivityFeed();
  Future<Result<void>> actOnRequest(
    String activityId,
    ActivityActionType action,
  );
}
