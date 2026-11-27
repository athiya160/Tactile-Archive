import '../error/failures.dart';

class Result<T> {
  final T? data;
  final Failure? failure;

  Result._({this.data, this.failure});

  factory Result.success(T data) => Result._(data: data);
  factory Result.failure(Failure failure) => Result._(failure: failure);

  bool get isSuccess => failure == null;
  bool get isFailure => failure != null;

  void fold(void Function(Failure) onError, void Function(T) onSuccess) {
    if (isFailure) {
      onError(failure!);
    } else {
      onSuccess(data as T);
    }
  }
}
