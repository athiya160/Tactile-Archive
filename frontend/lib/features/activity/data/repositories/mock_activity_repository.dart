import 'dart:async';

import '../../../../core/utils/result.dart';
import '../../domain/entities/activity_item.dart';
import '../../domain/repositories/activity_repository.dart';

class MockActivityRepository implements ActivityRepository {
  final List<ActivityItem> _activities = [
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
    await Future.delayed(const Duration(milliseconds: 450));
    return Result.success(List<ActivityItem>.from(_activities));
  }

  @override
  Future<Result<void>> actOnRequest(
    String activityId,
    ActivityActionType action,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return Result.success(null);
  }
}
