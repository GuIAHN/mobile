import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/top_providers_result.dart';
import '../repositories/home_repository.dart';

class GetTopProvidersUseCase {
  final HomeRepository _repository;

  GetTopProvidersUseCase(this._repository);

  Future<Either<Failure, TopProvidersResult>> call({
    double? lat,
    double? lng,
  }) {
    return _repository.getTopProviders(lat: lat, lng: lng);
  }
}
