import 'package:equatable/equatable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/activity_item.dart';
import '../repositories/activity_repository.dart';

class ActOnRequestParams extends Equatable {
  final String activityId;
  final ActivityActionType action;

  const ActOnRequestParams({required this.activityId, required this.action});

  @override
  List<Object?> get props => [activityId, action];
}

class ActOnRequest implements UseCase<void, ActOnRequestParams> {
  final ActivityRepository repository;

  ActOnRequest(this.repository);

  @override
  Future<Result<void>> call(ActOnRequestParams params) {
    return repository.actOnRequest(params.activityId, params.action);
  }
}
