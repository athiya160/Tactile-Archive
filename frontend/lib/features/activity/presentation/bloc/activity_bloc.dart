import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/activity_item.dart';
import '../../domain/usecases/act_on_request.dart';
import '../../domain/usecases/get_activity_feed.dart';

part 'activity_event.dart';
part 'activity_state.dart';

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final GetActivityFeed getActivityFeed;
  final ActOnRequest actOnRequest;

  ActivityBloc({required this.getActivityFeed, required this.actOnRequest})
    : super(ActivityInitial()) {
    on<ActivityStarted>(_onStarted);
    on<ActivityApprovePressed>(_onApprovePressed);
    on<ActivityDenyPressed>(_onDenyPressed);
    on<ActivityReturnNowPressed>(_onReturnNowPressed);
    on<ActivityViewOrderPressed>(_onViewOrderPressed);
  }

  Future<void> _onStarted(
    ActivityStarted event,
    Emitter<ActivityState> emit,
  ) async {
    emit(ActivityLoading());
    final result = await getActivityFeed(NoParams());
    result.fold(
      (failure) => emit(ActivityError(failure.message)),
      (items) => emit(ActivityLoaded(items: items)),
    );
  }

  Future<void> _onApprovePressed(
    ActivityApprovePressed event,
    Emitter<ActivityState> emit,
  ) async {
    await _handleAction(event.activityId, ActivityActionType.approve, emit);
  }

  Future<void> _onDenyPressed(
    ActivityDenyPressed event,
    Emitter<ActivityState> emit,
  ) async {
    await _handleAction(event.activityId, ActivityActionType.deny, emit);
  }

  Future<void> _onReturnNowPressed(
    ActivityReturnNowPressed event,
    Emitter<ActivityState> emit,
  ) async {
    await _handleAction(event.activityId, ActivityActionType.returnNow, emit);
  }

  Future<void> _onViewOrderPressed(
    ActivityViewOrderPressed event,
    Emitter<ActivityState> emit,
  ) async {
    await _handleAction(event.activityId, ActivityActionType.viewOrder, emit);
  }

  Future<void> _handleAction(
    String activityId,
    ActivityActionType action,
    Emitter<ActivityState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ActivityLoaded) {
      return;
    }

    emit(currentState.copyWith(processingId: activityId, message: null));

    final result = await actOnRequest(
      ActOnRequestParams(activityId: activityId, action: action),
    );

    result.fold(
      (failure) {
        emit(
          currentState.copyWith(processingId: null, message: failure.message),
        );
      },
      (_) {
        final updatedItems = action == ActivityActionType.viewOrder
            ? currentState.items
            : currentState.items
                  .where((item) => item.id != activityId)
                  .toList();

        emit(
          currentState.copyWith(
            items: updatedItems,
            processingId: null,
            message: _messageForAction(action),
          ),
        );
      },
    );
  }

  String _messageForAction(ActivityActionType action) {
    switch (action) {
      case ActivityActionType.approve:
        return 'Rent request approved.';
      case ActivityActionType.deny:
        return 'Rent request denied.';
      case ActivityActionType.returnNow:
        return 'Return request submitted.';
      case ActivityActionType.viewOrder:
        return 'Order details opened.';
    }
  }
}
