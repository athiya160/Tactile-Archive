import 'package:equatable/equatable.dart';

enum ActivityItemType {
  rentRequest,
  returnOverdue,
  favoriteUpdate,
  purchaseConfirmation,
  follower,
}

enum ActivityActionType { approve, deny, returnNow, viewOrder }

class ActivityItem extends Equatable {
  final String id;
  final ActivityItemType type;
  final String title;
  final String description;
  final String timestamp;
  final List<ActivityActionType> availableActions;
  final bool isArchived;

  const ActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.availableActions = const [],
    this.isArchived = false,
  });

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    description,
    timestamp,
    availableActions,
    isArchived,
  ];
}
