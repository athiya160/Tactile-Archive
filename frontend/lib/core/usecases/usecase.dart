import '../utils/result.dart';

abstract class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

abstract class StreamUseCase<T, Params> {
  Stream<T> call(Params params);
}

class NoParams {}
