import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart';
import '../entities/rental_item.dart';
import '../repositories/rentals_repository.dart';

/// Fetches active rentals from repository with error handling.
class GetActiveRentals implements UseCase<List<RentalItem>, NoParams> {
  final RentalsRepository repository;

  GetActiveRentals(this.repository);

  @override
  Future<Result<List<RentalItem>>> call(NoParams params) async {
    try {
      return await repository.getActiveRentals();
    } catch (e) {
      return Result.failure(
        ServerFailure('Failed to load active rentals: ${e.toString()}'),
      );
    }
  }
}
