import '../../../../core/utils/result.dart';

import '../entities/rental_item.dart';

abstract class RentalsRepository {
  Future<Result<List<RentalItem>>> getActiveRentals();
}
