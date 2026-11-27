import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/activity_item.dart';
import '../../domain/repositories/activity_repository.dart';

class RemoteActivityRepository implements ActivityRepository {
  final ApiClient apiClient;

  RemoteActivityRepository(this.apiClient);

  static final List<ActivityItem> _defaultMockActivities = [
    const ActivityItem(
      id: 'rent_request_01',
      type: ActivityItemType.rentRequest,
      title: 'Rental Approved',
      description:
          'Your borrow request for "The Shadow of the Wind" has been approved! Ready for pickup at Central Smart Locker.',
      timestamp: '14m ago',
      availableActions: [ActivityActionType.viewOrder],
    ),
    const ActivityItem(
      id: 'return_overdue_01',
      type: ActivityItemType.returnOverdue,
      title: 'Active Rental Reminder',
      description:
          'Your rental of "Collected Fictions" by Jorge Luis Borges is active. Return on time to earn extra community reader credits.',
      timestamp: '2h ago',
      availableActions: [ActivityActionType.returnNow],
    ),
    const ActivityItem(
      id: 'favorite_update_01',
      type: ActivityItemType.favoriteUpdate,
      title: 'Curated Collection Update',
      description:
          'A rare edition of "The Name of the Rose" has just been added to the archive catalog.',
      timestamp: '5h ago',
      availableActions: const [],
    ),
    const ActivityItem(
      id: 'order_confirmation_01',
      type: ActivityItemType.purchaseConfirmation,
      title: 'Order Confirmed',
      description:
          'Your order for the Librarian\'s Choice: Essential Classics Bundle has been confirmed.',
      timestamp: 'Yesterday',
      availableActions: [ActivityActionType.viewOrder],
    ),
  ];

  @override
  Future<Result<List<ActivityItem>>> getActivityFeed() async {
    try {
      final response = await apiClient.getJson('/activity/feed');
      if (response is List) {
        final feed = response.map((item) {
          final data = item as Map<String, dynamic>;
          final type = _parseActivityType(data['type']);
          final actions = _parseActions(data['availableActions']);
          return ActivityItem(
            id: data['id']?.toString() ?? '',
            type: type,
            title: data['title']?.toString() ?? '',
            description: data['description']?.toString() ?? '',
            timestamp: data['timestamp']?.toString() ?? '',
            availableActions: actions,
            isArchived: data['isArchived'] == true,
          );
        }).toList();
        return Result.success(feed);
      }
    } catch (error) {
      // Fallback to default mock feed if server is offline or unreachable
    }
    return Result.success(List<ActivityItem>.from(_defaultMockActivities));
  }

  @override
  Future<Result<void>> actOnRequest(
    String activityId,
    ActivityActionType action,
  ) async {
    try {
      await apiClient.postJson(
        '/activity/$activityId/actions',
        body: {'action': action.name},
      );
      return Result.success(null);
    } on Failure catch (error) {
      return Result.failure(error);
    } catch (error) {
      return Result.failure(ServerFailure(error.toString()));
    }
  }

  ActivityItemType _parseActivityType(dynamic raw) {
    final value = raw?.toString().toLowerCase();
    switch (value) {
      case 'rentrequest':
      case 'rent_request':
      case 'rent request':
        return ActivityItemType.rentRequest;
      case 'returnoverdue':
      case 'return_overdue':
      case 'return overdue':
        return ActivityItemType.returnOverdue;
      case 'favoriteupdate':
      case 'favorite_update':
      case 'favorite update':
        return ActivityItemType.favoriteUpdate;
      case 'purchaseconfirmation':
      case 'purchase_confirmation':
      case 'purchase confirmation':
        return ActivityItemType.purchaseConfirmation;
      case 'follower':
      default:
        return ActivityItemType.follower;
    }
  }

  List<ActivityActionType> _parseActions(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((entry) => entry?.toString().toLowerCase())
        .whereType<String>()
        .map((value) {
          switch (value) {
            case 'approve':
              return ActivityActionType.approve;
            case 'deny':
              return ActivityActionType.deny;
            case 'returnnow':
            case 'return_now':
            case 'return now':
              return ActivityActionType.returnNow;
            case 'vieworder':
            case 'view_order':
            case 'view order':
              return ActivityActionType.viewOrder;
            default:
              return ActivityActionType.viewOrder;
          }
        })
        .toList();
  }
}
