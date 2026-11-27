part of 'activity_bloc.dart';

abstract class ActivityEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ActivityStarted extends ActivityEvent {}

class ActivityApprovePressed extends ActivityEvent {
  final String activityId;

  ActivityApprovePressed(this.activityId);

  @override
  List<Object?> get props => [activityId];
}

class ActivityDenyPressed extends ActivityEvent {
  final String activityId;

  ActivityDenyPressed(this.activityId);

  @override
  List<Object?> get props => [activityId];
}

class ActivityReturnNowPressed extends ActivityEvent {
  final String activityId;

  ActivityReturnNowPressed(this.activityId);

  @override
  List<Object?> get props => [activityId];
}

class ActivityViewOrderPressed extends ActivityEvent {
  final String activityId;

  ActivityViewOrderPressed(this.activityId);

  @override
  List<Object?> get props => [activityId];
}
