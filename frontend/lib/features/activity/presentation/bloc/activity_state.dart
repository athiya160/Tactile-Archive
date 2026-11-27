part of 'activity_bloc.dart';

abstract class ActivityState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ActivityInitial extends ActivityState {}

class ActivityLoading extends ActivityState {}

class ActivityError extends ActivityState {
  final String message;

  ActivityError(this.message);

  @override
  List<Object?> get props => [message];
}

class ActivityLoaded extends ActivityState {
  final List<ActivityItem> items;
  final String? message;
  final String? processingId;

  ActivityLoaded({required this.items, this.message, this.processingId});

  ActivityLoaded copyWith({
    List<ActivityItem>? items,
    String? message,
    String? processingId,
  }) {
    return ActivityLoaded(
      items: items ?? this.items,
      message: message,
      processingId: processingId,
    );
  }

  @override
  List<Object?> get props => [items, message, processingId];
}
